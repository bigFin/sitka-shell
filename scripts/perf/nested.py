"""Run only inside run-nested.sh's disposable non-networked namespace."""

import argparse
import concurrent.futures

import json
import mmap
import os
from pathlib import Path
import platform
import select
import shutil
import signal
import struct
import subprocess as sp
import tempfile
import time
from typing import Any
import zlib

SOURCE, OUT = Path("/frozen"), Path("/evidence")
CLK = os.sysconf("SC_CLK_TCK")
clock = time.monotonic_ns


def save(p, data):
    p.write_text(json.dumps(data, indent=2) + "\n")


def until(test, label, timeout=15, delay=0.025):
    start = clock()
    while (clock() - start) / 1e9 < timeout:
        if result := test():
            return result
        time.sleep(delay)
    raise RuntimeError("Timed out: " + label)


def snap(pid):
    base = Path(f"/proc/{pid}")
    # Skip pid/comm, whose parentheses or spaces must not change field indices.
    fields = (base / "stat").read_text().rsplit(")", 1)[1].split()
    mem = {
        k: int(v.split()[0])
        for k, v in (
            s.split(":", 1)
            for s in (base / "smaps_rollup").read_text().splitlines()[1:]
        )
    }
    threads, children = {}, {}
    for task in (base / "task").iterdir():
        try:
            threads[task.name] = {
                k: int(v)
                for k, v in (
                    s.split(":", 1) for s in (task / "status").read_text().splitlines()
                )
                if k.endswith("ctxt_switches")
            }
            for child in (task / "children").read_text().split():
                try:
                    children[child] = Path(f"/proc/{child}/comm").read_text().strip()
                except FileNotFoundError:
                    pass
        except FileNotFoundError:
            pass
    return dict(
        ns=clock(),
        cpu_ticks=int(fields[11]) + int(fields[12]),
        waited_child_ticks=int(fields[13]) + int(fields[14]),
        rss_KiB=mem["Rss"],
        pss_KiB=mem["Pss"],
        threads=threads,
        direct_children=children,
    )


class Probe:
    """Xvfb's mmap XWD screen. Only checksum small strips in Niri's window."""

    def __init__(self, file, geo):
        with file.open("rb") as f:
            self.fb = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        h = struct.unpack(">25I", self.fb[:100])
        self.start = h[0] + h[19] * 12
        assert h[1:3] == (7, 2) and h[11] == 32, h
        self.pitch = h[12]
        self.x, self.y, self.w, self.h = [geo[k] for k in ("X", "Y", "WIDTH", "HEIGHT")]
        assert (
            0 <= self.x < self.x + self.w <= h[4]
            and 0 <= self.y < self.y + self.h <= h[5]
        )

    def sig(self, region):
        top, bottom = {
            "top": (0.003, 0.09),
            "body": (0.10, 0.99),
            "all": (0.003, 0.99),
        }[region]
        rows = range(
            int(top * self.h), int(bottom * self.h), 4 if region == "top" else 10
        )
        # Centre-left bands avoid the usual pointer, left rail and output clock.
        values = []
        for y in rows:
            i = (
                self.start
                + (self.y + y) * self.pitch
                + (self.x + int(self.w * 0.38)) * 4
            )
            values.append(zlib.crc32(self.fb[i : i + 128]))
        return tuple(values)

    def trace(
        self, region, action, duration, before_action=None
    ) -> tuple[Any, dict[str, Any]]:
        reference = self.sig(region)
        pre = []
        for _ in range(10):
            time.sleep(0.008)
            pre.append(sum(a != b for a, b in zip(reference, self.sig(region))))
        if max(pre) >= 2:
            raise RuntimeError(f"Unstable pre-action framebuffer ROI: {pre}")
        if before_action is not None:
            before_action()
        start = clock()
        proc = action()
        samples = []
        prev = reference
        while (clock() - start) / 1e9 < duration:
            vals = self.sig(region)
            now = clock()
            diff = sum(a != b for a, b in zip(reference, vals))
            samples.append(
                [
                    round((now - start) / 1e6, 3),
                    diff,
                    sum(a != b for a, b in zip(prev, vals)),
                ]
            )
            prev = vals
            time.sleep(0.008)
        changed = [s[0] for s in samples if s[1] >= 2]
        if not changed:
            raise RuntimeError("No visible output change in " + region)
        return proc, dict(
            region=region,
            start_monotonic_ns=start,
            pre_changed_bands=pre,
            first_observed_ms=changed[0],
            samples=samples,
        )


def one(index, seconds, evidence):
    with tempfile.TemporaryDirectory(prefix="s-", dir="/tmp") as name:
        root = Path(name)
        env = {
            k: v
            for k, v in os.environ.items()
            if k
            in (
                "PATH",
                "SITKA_LIB_DIR",
                "SITKA_XKB_RULES_PATH",
                "QML_IMPORT_PATH",
                "QML2_IMPORT_PATH",
                "QT_PLUGIN_PATH",
                "LOCALE_ARCHIVE",
                "LD_LIBRARY_PATH",
                "FONTCONFIG_FILE",
                "FONTCONFIG_PATH",
                "XKB_CONFIG_ROOT",
                "TZDIR",
            )
        }
        for k, v in {
            "HOME": "home",
            "XDG_CONFIG_HOME": "cfg",
            "XDG_STATE_HOME": "state",
            "XDG_DATA_HOME": "data",
            "XDG_CACHE_HOME": "cache",
            "XDG_RUNTIME_DIR": "r",
            "XDG_DATA_DIRS": "share",
            "XDG_CONFIG_DIRS": "syscfg",
            "SITKA_CONFIG_DIR": "sitka",
        }.items():
            (root / v).mkdir(mode=0o700)
            env[k] = str(root / v)
        env.update(
            XDG_CURRENT_DESKTOP="niri",
            XDG_SESSION_TYPE="wayland",
            QT_QPA_PLATFORM="wayland",
            LIBGL_ALWAYS_SOFTWARE="1",
            LP_NUM_THREADS="4",
            QSG_INFO="1",
            LANG="C.UTF-8",
            TZ="UTC",
            USER="observer",
            LOGNAME="observer",
            TMPDIR="/tmp",
            DBUS_SYSTEM_BUS_ADDRESS="unix:path=/tmp/no-system-bus",
        )
        runtime = root / "r"
        bus = runtime / "bus"
        env["DBUS_SESSION_BUS_ADDRESS"] = "unix:path=" + str(bus)
        names = [
            "org.freedesktop.DBus",
            "org.freedesktop.Notifications",
            "org.kde.StatusNotifierWatcher",
            "org.freedesktop.ScreenSaver",
        ]
        acl = "".join(
            f'<allow own="{n}"/><allow send_destination="{n}"/>' for n in names
        )
        (root / "bus.conf").write_text(
            f'<busconfig><type>session</type><auth>EXTERNAL</auth><listen>unix:path={bus}</listen><policy context="default"><allow user="*"/><deny own="*"/><deny send_destination="*"/>{acl}<allow send_requested_reply="true"/><allow receive_sender="*"/><allow send_type="signal"/></policy></busconfig>'
        )
        (root / "niri.kdl").write_text(
            "xwayland-satellite { off; }\nhotkey-overlay { skip-at-startup; }\n"
        )
        config = json.loads((SOURCE / "config/presets/observatory.json").read_text())
        config["bar"] = {"revealMode": "always"}
        save(root / "sitka/shell.json", config)
        save(evidence / "config.json", config)
        wallpaper = str(SOURCE / "assets/wallpapers/observatory.svg")
        wall = root / "state/sitka/wallpaper/path.txt"
        wall.parent.mkdir(parents=True)
        wall.write_text(wallpaper)
        apps = (
            "Terminal",
            "Text Editor",
            "Calendar",
            "Calculator",
            "Files",
            "Settings",
            "Music",
            "Web Browser",
        )
        appdir = root / "data/applications"
        appdir.mkdir()
        for i, title in enumerate(apps):
            (appdir / f"bench{i}.desktop").write_text(
                f"[Desktop Entry]\nType=Application\nName={title}\nExec=true\nIcon=application-x-executable\n"
            )
        kids = []
        records = {}
        cleanup = []
        probe = None

        def launch(tag, argv, **kwargs):
            with (evidence / (tag + ".log")).open("w") as log:
                p = sp.Popen(
                    argv,
                    env=env,
                    start_new_session=True,
                    stdout=log,
                    stderr=sp.STDOUT,
                    **kwargs,
                )
            kids.append((tag, p))
            return p

        def run(*argv, check=True):
            return sp.run(
                argv, env=env, text=True, capture_output=True, check=check, timeout=7
            )

        def check(p):
            if p.poll() is not None:
                raise RuntimeError(f"PID {p.pid} exited {p.returncode}; see {evidence}")

        try:
            daemon = launch(
                "bus",
                ["dbus-daemon", "--nofork", "--config-file=" + str(root / "bus.conf")],
            )
            until(lambda: (check(daemon) or bus.is_socket()), "private bus")
            services = run(
                "busctl",
                "--address=" + env["DBUS_SESSION_BUS_ADDRESS"],
                "call",
                "org.freedesktop.DBus",
                "/org/freedesktop/DBus",
                "org.freedesktop.DBus",
                "ListActivatableNames",
            ).stdout.strip()
            assert services == 'as 1 "org.freedesktop.DBus"', services
            r, w = os.pipe()
            try:
                xvfb = launch(
                    "xvfb",
                    [
                        "Xvfb",
                        "-displayfd",
                        str(w),
                        "-fbdir",
                        str(root),
                        "-screen",
                        "0",
                        "1600x1024x24",
                        "-nolisten",
                        "tcp",
                    ],
                    pass_fds=(w,),
                )
                assert select.select([r], [], [], 8)[0]
                display = os.read(r, 30).decode().strip()
                assert display.isdecimal()
                env["DISPLAY"] = ":" + display
                check(xvfb)
            finally:
                os.close(w)
                os.close(r)
            niri = launch(
                "niri",
                [
                    "env",
                    "LD_LIBRARY_PATH=" + os.environ["BENCH_NIRI_LIBS"],
                    "niri",
                    "-c",
                    str(root / "niri.kdl"),
                ],
            )

            def sockets():
                check(niri)
                ws = [p for p in runtime.glob("wayland-*") if p.is_socket()]
                ns = [p for p in runtime.glob("niri.*.sock") if p.is_socket()]
                return (ws[0].name, str(ns[0])) if len(ws) == len(ns) == 1 else None

            env["WAYLAND_DISPLAY"], env["NIRI_SOCKET"] = until(sockets, "Niri sockets")
            output = json.loads(run("niri", "msg", "--json", "outputs").stdout)
            assert len(output) == 1
            oname, info = next(iter(output.items()))
            assert (
                info["logical"]["width"],
                info["logical"]["height"],
                info["logical"]["scale"],
            ) == (1280, 800, 1)
            xd = os.environ["BENCH_XDOTOOL"]
            windows = run(
                xd, "search", "--onlyvisible", "--name", "^[Nn]iri$"
            ).stdout.split()
            assert len(windows) == 1
            window = windows[0]
            run(xd, "windowfocus", "--sync", window)
            geom = {
                k: int(v)
                for k, v in (
                    line.split("=")
                    for line in run(
                        xd, "getwindowgeometry", "--shell", window
                    ).stdout.splitlines()
                )
            }
            assert (geom["WIDTH"], geom["HEIGHT"]) == (1280, 800)
            probe = Probe(root / "Xvfb_screen0", geom)
            qs = shutil.which("qs", path=env["PATH"]) or shutil.which(
                "quickshell", path=env["PATH"]
            )
            ipc = [qs, "-p", str(SOURCE), "ipc", "call"]
            records.update(
                index=index,
                clock_ticks_per_second=CLK,
                output=output,
                window=geom,
                apps=apps,
                bus_activatable=services,
                private_runtime=str(runtime),
                kernel=platform.release(),
                renderer=run("glxinfo", "-B").stdout,
                qs=qs,
                niri_version=run("niri", "--version").stdout.strip(),
                host_loadavg=Path("/proc/loadavg").read_text().strip(),
                qml_import_path=env["QML_IMPORT_PATH"],
                session_bus_acl=(root / "bus.conf").read_text(),
                interactions={},
                phases={},
            )
            time.sleep(0.4)

            def ready(shell):
                def attempt():
                    check(shell)
                    result = run(*ipc, "drawers", "list", check=False)
                    return (
                        clock()
                        if result.returncode == 0
                        and "launcher" in result.stdout.split()
                        else None
                    )

                return until(attempt, "shell IPC", 25, 0.035)

            with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:

                def startup():
                    shell = launch("sitka", [qs, "-p", str(SOURCE)])
                    return shell, executor.submit(ready, shell)

                (shell, future), trace = probe.trace("all", startup, 3.0)
                records["startup"] = trace
                trace["drawers_ipc_ms"] = (
                    future.result() - trace["start_monotonic_ns"]
                ) / 1e6
            assert run(*ipc, "wallpaper", "get").stdout.strip() == wallpaper

            def stats():
                return json.loads(run(*ipc, "stateStats", "get").stdout)

            def phase(name):
                time.sleep(1.3)
                before = stats()
                a = {n: snap(p.pid) for n, p in [("shell", shell), ("niri", niri)]}
                time.sleep(seconds)
                b = {n: snap(p.pid) for n, p in [("shell", shell), ("niri", niri)]}
                after = stats()
                records["phases"][name] = dict(
                    before=a, after=b, stats_before=before, stats_after=after
                )
                save(evidence / "raw.json", records)
                print(f"run {index} {name}", flush=True)
                run("grim", "-o", oname, str(evidence / (name + ".png")))
                time.sleep(0.4)

            def event(name, region, argv):
                def snapshot_before():
                    nonlocal before
                    before = {
                        n: snap(p.pid) for n, p in [("shell", shell), ("niri", niri)]
                    }

                before = {}
                p, trace = probe.trace(
                    region, lambda: launch(name, argv), 1.35, snapshot_before
                )
                after = {n: snap(p.pid) for n, p in [("shell", shell), ("niri", niri)]}
                assert p.wait(timeout=5) == 0
                trace.update(before=before, after=after)
                records["interactions"][name] = trace

            phase("closed")
            toggle = ipc + ["drawers", "toggle"]
            event("launcher-first", "body", toggle + ["launcher"])
            phase("launcher")
            event("launcher-close", "body", toggle + ["launcher"])
            time.sleep(0.5)
            event("launcher-warm", "body", toggle + ["launcher"])
            event("launcher-warm-close", "body", toggle + ["launcher"])
            time.sleep(0.5)
            event("dashboard-open", "top", toggle + ["dashboard"])
            state = stats()["drawers"]
            assert state["dashboardVisible"] and not state["dashboardExpanded"]
            phase("dashboard-compact")
            assert run(xd, "getwindowfocus").stdout.strip() == window
            event("dashboard-expand", "body", [xd, "key", "space"])
            assert stats()["drawers"]["dashboardExpanded"]
            phase("dashboard-expanded")
            event("dashboard-close", "body", [xd, "key", "Escape"])
            assert not stats()["drawers"]["dashboardVisible"]
            phase("returned")
            save(evidence / "raw.json", records)
        finally:
            if probe is not None:
                probe.fb.close()
            for tag, p in reversed(kids):
                try:
                    os.killpg(p.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
                try:
                    p.wait(timeout=2)
                except sp.TimeoutExpired:
                    os.killpg(p.pid, signal.SIGKILL)
                    p.wait()
                cleanup.append([tag, p.pid, p.returncode])
            save(
                evidence / "cleanup.json",
                {
                    "reaped": cleanup,
                    "remaining_named_groups": [
                        tag for tag, p in kids if Path(f"/proc/{p.pid}").exists()
                    ],
                },
            )
    assert not root.exists()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--idle-seconds", type=float, default=4)
    args = ap.parse_args()
    assert args.runs >= 1 and args.idle_seconds >= 1
    assert Path("/proc/1/comm").read_text().strip() in (
        "bwrap",
        "bwrap-wrapped",
        ".bwrap-wrapped",
    ), "Must run in private PID namespace"
    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, lambda s, f: exit(128 + s))
    for i in range(1, args.runs + 1):
        dest = OUT / f"run-{i:02}"
        dest.mkdir()
        one(i, args.idle_seconds, dest)
    (OUT / "complete").write_text(f"{args.runs} runs, {args.idle_seconds}s per phase\n")


if __name__ == "__main__":
    main()
