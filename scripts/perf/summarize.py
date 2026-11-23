"""Summarize only a complete cohort; keep all per-run calculations as CSV."""

import argparse
import csv
import hashlib
import json
from pathlib import Path
import re
from statistics import median
from typing import Any

PHASES = ("closed", "launcher", "dashboard-compact", "dashboard-expanded", "returned")
EVENTS = (
    "launcher-first",
    "launcher-close",
    "launcher-warm",
    "launcher-warm-close",
    "dashboard-open",
    "dashboard-expand",
    "dashboard-close",
)
ROLES = ("shell", "niri")


def csvfile(path, rows):
    with path.open("w", newline="") as out:
        writer = csv.DictWriter(out, fieldnames=rows[0])
        writer.writeheader()
        writer.writerows(rows)


def stats(a, b, hz):
    seconds = (b["ns"] - a["ns"]) / 1e9
    ticks = b["cpu_ticks"] - a["cpu_ticks"]
    shared = a["threads"].keys() & b["threads"].keys()
    cs = sum(
        sum(b["threads"][t].values()) - sum(a["threads"][t].values()) for t in shared
    )
    return dict(
        seconds=seconds,
        cpu_ms=ticks * 1000 / hz,
        cpu_pct=100 * ticks / (hz * seconds),
        switches_per_s=cs / seconds,
        rss_MiB=b["rss_KiB"] / 1024,
        pss_MiB=b["pss_KiB"] / 1024,
        waited_child_ms=(b["waited_child_ticks"] - a["waited_child_ticks"]) * 1000 / hz,
        surviving_threads=len(shared),
        changed_thread_ids=len(a["threads"].keys() ^ b["threads"].keys()),
        direct_children=";".join(sorted(b["direct_children"].values())),
    )


def burst(trace):
    samples = trace["samples"]
    prev = 0
    changed = []
    gaps = []
    for t, _, d in samples:
        gaps.append(t - prev)
        prev = t
        if t < trace["first_observed_ms"] or d == 0:
            continue
        if changed and t - changed[-1] > 150:
            break
        changed.append(t)
    intervals = [b - a for a, b in zip(changed, changed[1:])]
    return dict(
        first_observed_ms=trace["first_observed_ms"],
        sampled_changes=len(changed),
        median_change_gap_ms=median(intervals) if intervals else None,
        max_change_gap_ms=max(intervals, default=None),
        sample_gap_median_ms=median(gaps),
        sample_gap_max_ms=max(gaps),
    )


def main(root):
    complete = (root / "complete").read_text()
    match = re.fullmatch(r"(\d+) runs, ([\d.]+)s per phase\n", complete)
    assert match
    count = int(match[1])
    dirs = sorted(root.glob("run-*"))
    assert len(dirs) == count
    phases = []
    events = []
    starts = []
    polls = []
    children = set()
    loads = []
    for i, d in enumerate(dirs, 1):
        r = json.loads((d / "raw.json").read_text())
        hz = r["clock_ticks_per_second"]
        assert (
            r["index"] == i
            and tuple(r["phases"]) == PHASES
            and tuple(r["interactions"]) == EVENTS
        )
        assert (
            json.loads((d / "cleanup.json").read_text())["remaining_named_groups"] == []
        )
        assert (
            "llvmpipe" in (d / "sitka.log").read_text()
            and "Configuration Loaded" in (d / "sitka.log").read_text()
        )
        starts.append(
            {
                "run": i,
                "visible_ms": r["startup"]["first_observed_ms"],
                "ipc_ms": r["startup"]["drawers_ipc_ms"],
            }
        )
        loads.append(r["host_loadavg"].split()[0])
        for name, phase in r["phases"].items():
            row: dict[str, Any] = {"run": i, "phase": name}
            poll = {"run": i, "phase": name}
            for p in ROLES:
                s = stats(phase["before"][p], phase["after"][p], hz)
                row.update({f"{p}_{k}": v for k, v in s.items()})
                children.update(phase["before"][p]["direct_children"].values())
                children.update(phase["after"][p]["direct_children"].values())
            for metric in ("cpu_pct", "switches_per_s", "pss_MiB", "waited_child_ms"):
                row["total_" + metric] = sum(row[p + "_" + metric] for p in ROLES)
            phases.append(row)
            for service in ("systemUsage", "sysMonitor"):
                a, b = [phase[k][service] for k in ("stats_before", "stats_after")]
                for k, val in b.items():
                    if k.endswith("PollCount"):
                        poll[f"{service}.{k}"] = val - a[k]
                    elif k.endswith("Active"):
                        poll[f"{service}.{k}"] = val
            polls.append(poll)
        for name, trace in r["interactions"].items():
            row = dict(run=i, event=name, **burst(trace))
            row.update(
                {
                    p + "_cpu_ms": stats(trace["before"][p], trace["after"][p], hz)[
                        "cpu_ms"
                    ]
                    for p in ROLES
                }
            )
            events.append(row)
    for name, rows in [
        ("startup", starts),
        ("phases", phases),
        ("interactions", events),
        ("polling", polls),
    ]:
        csvfile(root / (name + ".csv"), rows)

    def vals(rows, key):
        return [row[key] for row in rows if row[key] is not None]

    def mid(rows, key, d=1):
        a = vals(rows, key)
        return f"{median(a):.{d}f}" if a else "—"

    def spread(rows, key, d=1):
        a = vals(rows, key)
        return f"{median(a):.{d}f} [{min(a):.{d}f}–{max(a):.{d}f}]" if a else "—"

    def table(headers, rows):
        return "\n".join(
            [
                "| " + " | ".join(headers) + " |",
                "|" + "---|" * len(headers),
                *["| " + " | ".join(map(str, row)) + " |" for row in rows],
            ]
        )

    phase_sets = {p: [x for x in phases if x["phase"] == p] for p in PHASES}
    event_sets = {e: [x for x in events if x["event"] == e] for e in EVENTS}
    target = max(PHASES, key=lambda p: median(vals(phase_sets[p], "total_cpu_pct")))
    slow = max(EVENTS, key=lambda e: median(vals(event_sets[e], "first_observed_ms")))
    phase_rows = []
    mem_rows = []
    poll_rows = []
    event_rows = []
    for p, rows in phase_sets.items():
        phase_rows.append(
            [
                p,
                mid(rows, "shell_cpu_pct"),
                mid(rows, "niri_cpu_pct"),
                spread(rows, "total_cpu_pct"),
                mid(rows, "shell_switches_per_s", 0),
                mid(rows, "niri_switches_per_s", 0),
            ]
        )
        mem_rows.append(
            [
                p,
                *[
                    mid(rows, f"{role}_{m}", 0)
                    for role in ROLES
                    for m in ("rss_MiB", "pss_MiB")
                ],
                spread(rows, "total_pss_MiB", 0),
            ]
        )
        ps = [x for x in polls if x["phase"] == p]
        poll_rows.append(
            [
                p,
                ", ".join(
                    k + ": " + str(sum(vals(ps, k)))
                    for k in ps[0]
                    if k.endswith("PollCount") and sum(vals(ps, k))
                )
                or "none",
                sum(vals(rows, "total_waited_child_ms")),
            ]
        )
    for e, rows in event_sets.items():
        event_rows.append(
            [
                e,
                spread(rows, "first_observed_ms", 0),
                mid(rows, "shell_cpu_ms", 0),
                mid(rows, "niri_cpu_ms", 0),
                mid(rows, "sampled_changes"),
                mid(rows, "median_change_gap_ms"),
                mid(rows, "max_change_gap_ms"),
            ]
        )
    digest = hashlib.sha256((root / "baseline.sha256").read_bytes()).hexdigest()
    target_polls = sum(
        v
        for row in polls
        if row["phase"] == target
        for k, v in row.items()
        if k.endswith("PollCount")
    )
    assert digest == "636da5d5b3bbc0ae8f7426a3f06b22e41429a48c15f8359b8481efcbc21e42fd"
    md = f"""# Observatory: nested software baseline

**Profile `{target}` first.** It used {spread(phase_sets[target], "total_cpu_pct")}% of one core (shell + compositor), versus {spread(phase_sets["closed"], "total_cpu_pct")}% closed and {spread(phase_sets["returned"], "total_cpu_pct")}% after dismissal. The slowest measured drawer response was `{slow}` at {spread(event_sets[slow], "first_observed_ms", 0)} ms. These are observed costs, not attribution to any shader, collector or timer. No optimization was applied.

## Fixture and sample

- Frozen working copy based on `914f79c3eb2caf718b36fae1f0c3df3255e97969`; SHA-256 of the verified 358-file manifest: `{digest}`. This is **not** a benchmark of the clean runner branch HEAD.
- {count} independent namespace-local Xvfb/Niri/Quickshell starts with fresh private HOME/XDG and Qt caches; kernel page cache is not flushed. One first and one same-process warm launcher open per start; fixed order. Each state has {count} endpoint pairs of {match[2]} seconds after a 1.3 s settling interval. Reported summaries are medians; brackets are observed min–max, not confidence intervals.
- One 1280×800 Niri Winit output at 1× / nominal 60 Hz, 1600×1024 Xvfb parent, OpenGL Mesa llvmpipe (four worker threads per renderer), no hardware GPU. Observatory opaque preset, dithering intensity 0.12, always-revealed bar, fixed SVG wallpaper and eight fixture desktop entries, empty query. Dashboard expanded with Space and dismissed with Escape on the verified private focused window. No actual desktop, audio, weather, power, quota or seat services. Host 1 min load averages at start: {", ".join(loads)}; background scheduling is not controlled.

## Startup and drawer response

Shell process launch → first observed changed output bands: **{spread(starts, "visible_ms", 0)} ms**. Launch → successful `drawers list` response: **{spread(starts, "ipc_ms", 0)} ms**. These are different endpoints: IPC is polled, and neither measures login-to-desktop or physical scanout.

{table(["Action", "First observed output, ms", "Shell CPU ms", "Niri CPU ms", "Observed changes", "Median update gap, ms", "Max update gap, ms¹"], event_rows)}

¹ Start just before spawning the private IPC client or `xdotool` (includes its overhead). Xvfb mmap screen sampled ~8 ms apart; a change requires two 32-pixel-wide bands in the action region to differ from pre-action pixels. Ten stable pre-samples guard against unrelated motion. Update gaps are within the first burst of changed samples (stop at a gap >150 ms), median across runs of each run’s median or max. They are **observed band changes, not compositor frame IDs, vsync pacing, dropped frames or presentation timestamps**. Changes outside the region, repeated identical buffers, torn reads and coalesced updates are possible. CPU covers a fixed ~1.35 s action window, not just latency. The sampler’s CPU, Xvfb and IPC processes are excluded from the two-process total.

## Steady-state CPU, context switches and memory

{table(["State", "Shell CPU %", "Niri CPU %", "Combined CPU % [range]", "Shell CS/s", "Niri CS/s"], phase_rows)}

100% means one logical CPU. CPU is the process-wide delta of `/proc/PID/stat` user + system ticks. CS/s is **not wakeups**: it sums voluntary + involuntary switches across thread IDs present at both endpoints; short-lived threads are missed. No access to hardware wakeups or power counters is claimed. No framebuffer sampling or screenshots run inside these steady-state windows.

{table(["State", "Shell RSS MiB", "Shell PSS MiB", "Niri RSS MiB", "Niri PSS MiB", "Combined PSS MiB [range]"], mem_rows)}

Values are end-of-window `smaps_rollup` snapshots. PSS apportions shared pages; RSS is not summed. Retained memory after closing is not evidence of a leak.

## Service and child activity

{table(["State", f"Positive poll-counter increments, total over {count} windows", "Waited child CPU ms (sum)"], poll_rows)}

`stateStats get` was read just before/after each window. Counts cover only instrumented `systemUsage` and `sysMonitor` domains; detailed counters, flags and drawer states are in `polling.csv` and raw JSON. Direct child names visible at phase endpoints: {", ".join(sorted(children)) or "none"}. Waited child ticks are accounted only when reaped, not total subprocess work; endpoint child lists miss short-lived processes. No exec tracing was enabled.

## Interpretation and reproduction

The `{target}` state accumulated **{target_polls} instrumented poll increments** over its {count} steady-state windows. The next useful test is to trace which shell surfaces keep submitting updates in that state and whether the compositor continues repainting them. That would distinguish rendering work from uninstrumented background activity; this baseline does not.

No faithful all-effects-off switch was identified in the frozen source. `appearance.dithering.enabled` controls dither, `enableFilletEffects` controls fillets and `shaders.enabled` controls a separate optional shader path; none is a master switch for normal Observatory. No misleading effects-off comparison was run. This fixture does not measure physical input, direct DRM scanout, GPU power, laptop battery, or the cost of real host services. It does not prove no frames occur while closed.

Reproduce from the runner checkout, choosing a **new** evidence directory:

```sh
scripts/perf/run-nested.sh ../baseline ../perf-evidence/repeat --runs {count} --idle-seconds {match[2]}
python3 scripts/perf/summarize.py ../perf-evidence/repeat
```

`run-*/raw.json`: timed raw band samples `[elapsed_ms, changed_vs_reference, changed_vs_previous]`, `/proc` endpoints, service snapshots, output configuration, renderer and process paths. Each run also has five state PNGs, shell/compositor logs and `cleanup.json`. CSVs preserve one row per observation; this report uses only the repetitions in this directory. Pair and interleave a candidate before setting a regression budget; profile the identified high-cost state before changing a specific effect.
"""
    (root / "report.md").write_text(md)
    print(root / "report.md")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("evidence", type=Path)
    main(ap.parse_args().evidence)
