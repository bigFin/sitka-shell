#!/usr/bin/env python3
"""Render the 12-view board. Inputs are read-only; output is separate from source."""

import argparse
import base64
import hashlib
import json
import math

from pathlib import Path
import shutil
import subprocess
import tempfile
import time
from urllib.request import urlopen
from PIL import Image, ImageChops, ImageDraw, ImageFont
from websockets.sync.client import connect
from scenes import APPS, DIRECTIONS, STATES, document

HERE = Path(__file__).resolve().parent
SIZE = 1280, 800
LIVE_FILES = {
    "launcher": "launcher",
    "compact": "dashboard",
    "expanded": "dashboard-expanded",
}
SOURCE_DIGESTS = {
    "desktop": "709625092d308397d89b3d1721c4890f89bfd8bf96fb845bbb7637b441d48a08",
    "launcher": "547f49e85d637a16c64b8e72903b994369d7cbaf422f0a93e3482a5e7e47529a",
    "dashboard": "7c7101468a842a6e118adab857aaa43d4d84b2dad9498d5ed920bb933ae3d8d0",
    "dashboard-expanded": "bf036280d97b75c91ef45e5205726c870a9d8de7131a2d70d9d8fed13ad513d9",
}
SOURCE_MANIFEST = "636da5d5b3bbc0ae8f7426a3f06b22e41429a48c15f8359b8481efcbc21e42fd"
NAMES = {"live": "Current Observatory", **DIRECTIONS}
SUB = {
    "live": "Live capture  /  Nested Niri",
    "sun": "A  /  Ceramic joinery",
    "mission": "B  /  Framed instrument bays",
    "vfd": "C  /  Smoked readout glass",
}
LIVE_BOXES = {
    "launcher": (326, 173, 1007, 800),
    "compact": (215, 0, 1122, 79),
    "expanded": (215, 0, 1122, 619),
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def cdp_session(browser, pages, out):
    # Isolated user directory and WebSocket on loopback. No external page requests.
    with tempfile.TemporaryDirectory(prefix="obs-design-") as tmp:
        with subprocess.Popen(
            [
                browser,
                "--headless=new",
                "--disable-gpu",
                "--no-first-run",
                "--no-default-browser-check",
                "--disable-background-networking",
                "--disable-component-update",
                "--disable-sync",
                "--remote-debugging-address=127.0.0.1",
                "--remote-debugging-port=0",
                "--force-device-scale-factor=1",
                "--font-render-hinting=none",
                "--user-data-dir=" + tmp,
                "about:blank",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ) as proc:
            try:
                portfile = Path(tmp) / "DevToolsActivePort"
                for _ in range(160):
                    if proc.poll() is not None:
                        raise RuntimeError("Headless Chromium failed to start")
                    if portfile.is_file() and portfile.read_text().strip():
                        break
                    time.sleep(0.05)
                port = int(portfile.read_text().splitlines()[0])
                targets = json.load(
                    urlopen(f"http://127.0.0.1:{port}/json/list", timeout=3)
                )
                target = next(t for t in targets if t["type"] == "page")
                with connect(
                    target["webSocketDebuggerUrl"],
                    max_size=12 * 1024 * 1024,
                    open_timeout=8,
                ) as ws:
                    req = 0

                    def call(method, **params):
                        nonlocal req
                        req += 1
                        ws.send(json.dumps(dict(id=req, method=method, params=params)))
                        while True:
                            m = json.loads(ws.recv(timeout=12))
                            if m.get("id") == req:
                                if "error" in m:
                                    raise RuntimeError(m)
                                return m["result"]

                    def val(expr):
                        r = call(
                            "Runtime.evaluate",
                            expression=expr,
                            returnByValue=True,
                            awaitPromise=True,
                        )
                        if r.get("exceptionDetails"):
                            raise RuntimeError(r["exceptionDetails"])
                        return r["result"].get("value")

                    call(
                        "Emulation.setDeviceMetricsOverride",
                        width=SIZE[0],
                        height=SIZE[1],
                        deviceScaleFactor=1,
                        mobile=False,
                    )
                    for key, state, path in pages:
                        url = path.as_uri()
                        call("Page.navigate", url=url)
                        for _ in range(180):
                            if (
                                val("location.href") == url
                                and val("document.readyState") == "complete"
                            ):
                                break
                            time.sleep(0.025)
                        val(
                            "(async()=>{await Promise.all([...document.fonts].map(f=>f.load()));await document.fonts.ready;await new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)));return true})()"
                        )
                        result = val(
                            """(()=>{const m=document.querySelector('main'), box=m.getBoundingClientRect();const outside=[];const r=document.createRange();for(const el of m.querySelectorAll('*'))for(const n of el.childNodes)if(n.nodeType===Node.TEXT_NODE&&n.textContent.trim()){r.selectNodeContents(n);for(const b of r.getClientRects()) if(b.width>0&&(b.left<box.left||b.right>box.right||b.top<box.top||b.bottom>box.bottom))outside.push(n.textContent)}return {box:[box.left,box.top,box.right,box.bottom],outside,fonts:[...document.fonts].map(f=>[f.family,f.status]),viewport:[innerWidth,innerHeight,devicePixelRatio],text:m.innerText}})()"""
                        )
                        assert val("document.body.className") == f"{key} {state}"
                        assert (
                            result["viewport"] == [1280, 800, 1]
                            and not result["outside"]
                        ), result
                        assert all(st == "loaded" for _, st in result["fonts"]), result[
                            "fonts"
                        ]
                        if state == "launcher":
                            assert val(
                                '[...document.querySelectorAll(".result-text>b")].map(x=>x.textContent)'
                            ) == [a[1] for a in APPS]
                            assert (
                                val(
                                    'document.querySelector(".selected .result-text>b").textContent'
                                )
                                == "Accessibility"
                            )
                        else:
                            assert all(
                                value in result["text"]
                                for value in (
                                    "CPU",
                                    "Memory",
                                    "Storage",
                                    "Audio",
                                    "21%",
                                    "82%",
                                    "—",
                                )
                            )
                            if state == "expanded":
                                assert (
                                    val(
                                        'document.querySelector("nav .active").textContent'
                                    )
                                    == "Dashboard"
                                )
                                assert (
                                    val('document.querySelector(".today").textContent')
                                    == "22"
                                )
                        x, y, X, Y = result["box"]
                        assert x >= 0 and y >= 0 and X <= 1280 and Y <= 800, result[
                            "box"
                        ]
                        frame = out / "frames" / f"prototype-{key}-{state}.png"
                        frame.write_bytes(
                            base64.b64decode(
                                call("Page.captureScreenshot", format="png")["data"]
                            )
                        )
                        box = (
                            max(0, math.floor(x) - 9),
                            max(0, math.floor(y) - 9),
                            min(1280, math.ceil(X) + 13),
                            min(800, math.ceil(Y) + 16),
                        )
                        yield key, state, frame, box, result
            finally:
                proc.terminate()
                try:
                    proc.wait(timeout=6)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait()


def board(out, fonts, rows):
    W, cell, pad, gap = 2400, 564, 45, 18
    image = Image.new("RGB", (W, 1930), "#eceae2")
    d = ImageDraw.Draw(image)
    ink = "#192829"
    muted = "#47615b"
    border = "#bdc7ba"

    def f(which, size):
        return ImageFont.truetype(str(fonts[which]), size)

    def txt(x, y, s, which="ui", size=22, col=ink):
        d.text((x, y), s, font=f(which, size), fill=col, anchor="lt")

    txt(pad, 29, "SITKA   /   DESIGN STUDIES", "mono", 18, muted)
    txt(W - 390, 29, "ROUND 01     /     1280 × 800 @ 1×", "mono", 18, muted)
    txt(pad, 63, "Observatory", "bold", 60)
    txt(442, 87, "Command and Monitor", size=30)
    d.line((pad, 142, W - pad, 142), fill=ink, width=2)
    for j, (key, name) in enumerate(NAMES.items()):
        x = pad + j * (cell + gap)
        txt(x, 164, name, "bold", 31)
        txt(
            x,
            207,
            ("REFERENCE    " if key == "live" else "PROTOTYPE    ") + SUB[key],
            "mono",
            17,
            muted,
        )
    for i, (s, state) in enumerate(STATES.items()):
        y = 265 + i * 544
        txt(
            pad,
            y,
            {
                "launcher": "Command / Inspect",
                "compact": "Monitor / compact",
                "expanded": "Monitor / expanded",
            }[s],
            "bold",
            23,
        )
        info = {
            "launcher": "Empty query  •  Accessibility selected",
            "compact": "Summary strip  •  Space to expand",
            "expanded": "Dashboard tab  •  Storage 82%  /  Memory 21%",
        }[s]
        txt(pad + 264, y + 2, info, "mono", 17, muted)
        for j, key in enumerate(NAMES):
            x = pad + j * (cell + gap)
            frame = Image.open(rows[key, s]["frame"]).convert("RGB")
            pic = frame.resize((cell, 353), Image.Resampling.LANCZOS)
            image.paste(pic, (x, y + 38))
            d.rectangle((x - 1, y + 37, x + cell, y + 391), outline=border)
            # Unscaled glass/selection insets below the full frame, not on top of it.
            sample = {
                "launcher": [(357, 211), (359, 321), (272, 444), (288, 428)],
                "compact": [(227, 0), (399, 0), (437, 0), (398, 0)],
                "expanded": [(511, 241), (299, 153), (362, 119), (351, 163)],
            }[s][j]
            sx, sy = sample
            txt(
                x,
                y + 403,
                "1:1 DETAIL  /  "
                + {
                    "launcher": "first result",
                    "compact": "summary strip",
                    "expanded": "resource readings",
                }[s],
                "mono",
                14,
                muted,
            )
            image.paste(frame.crop((sx, sy, sx + cell, sy + 90)), (x, y + 426))
            d.rectangle((x - 1, y + 425, x + cell, y + 516), outline=border)
    txt(
        pad,
        1900,
        "Live images are untouched shell captures. Prototypes are static browser renderings on the captured desktop. Open index.html for complete native panels and fixture differences.",
        "mono",
        16,
        muted,
    )
    image.save(out / "comparison-board.png")


def gallery(out, rows):
    def rel(p):
        return p.relative_to(out).as_posix()

    blocks = []
    for s, state in STATES.items():
        cards = []
        for key, name in NAMES.items():
            e = rows[key, s]
            kind = "Live shell capture" if key == "live" else "Static prototype"
            frame, crop = rel(e["frame"]), rel(e["crop"])
            cards.append(
                f'<article><small>{kind}</small><h3>{name}</h3><a href="{frame}"><img src="{frame}" alt="{name}: {state}, full frame"></a><p><a href="{crop}">Native panel crop ↗</a> &nbsp; <a href="{frame}">Full frame ↗</a></p></article>'
            )
        blocks.append(
            f'<section><h2>{state}</h2><div class="grid">'
            + "".join(cards)
            + "</div></section>"
        )
    (out / "index.html").write_text(
        """<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Sitka Observatory — Round 1 review</title><style>@font-face{font-family:U;src:url(assets/ui.otf)}@font-face{font-family:U;src:url(assets/ui-bold.otf);font-weight:bold}*{box-sizing:border-box}body{margin:3vw;background:#eceae2;color:#192829;font:17px/1.45 U,sans-serif}h1{font-size:clamp(40px,6vw,85px);line-height:1;margin:.3em 0}h2{font-size:28px}h3{font-size:21px;margin:4px 0 10px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,250px),1fr));gap:15px}small{font-family:monospace;color:#425952}a{color:#154f48}img{display:block;width:100%}section{border-top:1px solid #8f9e92}p{max-width:85ch}article p{font-size:14px}a:focus-visible{outline:3px solid #61489b}</style><small>SITKA / MATERIAL STUDIES</small><h1>Observatory</h1><p><strong>Round 1.</strong> Look for the selected application first, then the larger of the two capacity readings. Each scene uses the same 1280 × 800 desktop at 1×. Compare composition in the <a href="comparison-board.png">full board</a>; inspect edges and type with the native crops below.</p>"""
        + "".join(blocks)
        + """<section><h2>Reading the comparison</h2><p>The first column is an unmodified capture of the nested QML shell. The studies use its closed desktop as their background and the same eight visible launcher entries, empty query and selected application. The live compact frame only shows the active window. The studies promote readings from the live expanded frame into the compact strip. “—” is unavailable, not zero; no thresholds, history, or alarm conditions are inferred.</p><p>All three expanded studies show the Dashboard tab, the same resource readings, NixOS release, date, weather, local time and empty media state. Time is normalized to 24-hour notation and uptime is intentionally shortened to the visible days and hours. Mission Control exposes the selected description in its inspect bay instead of under each result. The prototype key legends describe shell controls; none of the images or studies launch anything.</p></section></html>"""
    )


def main():
    p = argparse.ArgumentParser(description=__doc__)
    for k in ("captures", "snapshot", "manifest", "out", "mono", "ui", "ui-bold"):
        p.add_argument("--" + k, required=True, type=Path)
    p.add_argument("--browser", default="google-chrome")
    a = p.parse_args()
    out = a.out.resolve()
    snap = a.snapshot.resolve()
    for protected in (HERE, HERE.parents[2], snap, a.captures.resolve()):
        if out == protected or protected in out.parents or out in protected.parents:
            raise SystemExit("Output must not contain or sit inside source or inputs")
    assert sha(a.manifest) == SOURCE_MANIFEST, "Wrong source manifest"
    subprocess.run(
        ["sha256sum", "--check", "--quiet", str(a.manifest.resolve())],
        cwd=snap,
        check=True,
    )
    for name, digest in SOURCE_DIGESTS.items():
        src = a.captures / (name + ".png")
        assert sha(src) == digest and Image.open(src).size == SIZE, (
            f"Wrong capture: {src}"
        )
    for k in ("assets", "prototypes", "frames", "native"):
        (out / k).mkdir(exist_ok=True, parents=True)
    fonts = {"mono": a.mono, "ui": a.ui, "bold": a.ui_bold}
    assets = out / "assets"
    for k, name in [
        ("mono", "readings.ttf"),
        ("ui", "ui.otf"),
        ("bold", "ui-bold.otf"),
    ]:
        shutil.copyfile(fonts[k], assets / name)
    shutil.copytree(HERE / "font-notices", assets / "notices", dirs_exist_ok=True)
    shutil.copyfile(a.captures / "desktop.png", assets / "desktop.png")
    shutil.copyfile(HERE / "studies.css", out / "studies.css")
    rows = {}
    details = {}
    pages = []
    for s, n in LIVE_FILES.items():
        frame = out / "frames" / f"live-observatory-{s}.png"
        shutil.copyfile(a.captures / (n + ".png"), frame)
        rows["live", s] = {"frame": frame, "box": LIVE_BOXES[s]}
    for key in DIRECTIONS:
        for s in STATES:
            path = out / "prototypes" / f"{key}-{s}.html"
            path.write_text(document(key, s))
            pages.append((key, s, path))
    for key, s, frame, box, result in cdp_session(a.browser, pages, out):
        rows[key, s] = {"frame": frame, "box": box}
        details[key + "-" + s] = result
    desk = Image.open(assets / "desktop.png").convert("RGB")
    for (key, s), v in rows.items():
        img = Image.open(v["frame"]).convert("RGB")
        assert img.size == SIZE
        diff = ImageChops.difference(img, desk).getbbox()
        assert diff is not None
        x, y, X, Y = diff
        b = v["box"]
        assert (
            x >= b[0] - 24
            and y >= max(0, b[1] - 24)
            and X <= b[2] + 24
            and Y <= b[3] + 24
        ), "Pixels changed outside drawer and shadow"
        v["box"] = (
            max(0, min(x, b[0]) - 2),
            max(0, min(y, b[1]) - 2),
            min(SIZE[0], max(X, b[2]) + 2),
            min(SIZE[1], max(Y, b[3]) + 2),
        )
        crop = out / "native" / v["frame"].name
        img.crop(v["box"]).save(crop)
        v["crop"] = crop
    assert len(rows) == 12 and len(details) == 9
    board(out, fonts, rows)
    gallery(out, rows)
    (out / "render-report.json").write_text(
        json.dumps(
            {
                "sourceManifestSha256": SOURCE_MANIFEST,
                "liveImageSha256": SOURCE_DIGESTS,
                "browser": subprocess.check_output(
                    [a.browser, "--version"], text=True
                ).strip(),
                "fonts": {k: sha(v) for k, v in fonts.items()},
                "captureDetails": details,
                "frames": {
                    v["frame"].name: {"sha256": sha(v["frame"]), "crop": v["box"]}
                    for v in rows.values()
                },
            },
            indent=2,
        )
    )
    print(
        f"{len(rows)} 1280×800 frames; {len(details)} browser-rendered; 12 unscaled crops; board and index: {out}"
    )


if __name__ == "__main__":
    main()
