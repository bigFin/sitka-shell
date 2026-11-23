"""Static Observatory studies. No shell IPC, mock actions, or live telemetry."""

from datetime import date, timedelta
from html import escape

# Facts transcribed from the real launcher and expanded Dashboard captures.
APPS = (
    ("access", "Accessibility", "Improve keyboard and mouse accessibility"),
    (
        "network",
        "Advanced Network Configuration",
        "Manage and change your network connection settings",
    ),
    ("appearance", "Appearance", "Customize the look of your desktop"),
    (
        "battle",
        "Battle.net",
        "Launch Battle.net through the StarCraft II Proton prefix",
    ),
    ("bt", "Bluetooth Adapters", "Set Bluetooth Adapter Properties"),
    ("bt", "Bluetooth Manager", "Blueman Bluetooth Manager"),
    ("btop", "btop++", "System Monitor"),
    ("buzz", "Buzz", "Buzz desktop app"),
)
READINGS = [("CPU", None), ("Memory", 21), ("Storage", 82), ("Audio", None)]
TABS = ["Dashboard", "Media", "Performance", "Niri", "Usage"]
DIRECTIONS = {
    "sun": "Sun Workstation",
    "mission": "Mission Control",
    "vfd": "VFD Terminal",
}
STATES = {
    "launcher": "Command / Inspect",
    "compact": "Monitor · Compact",
    "expanded": "Monitor · Expanded",
}
ICONS = {
    "access": '<circle cx="12" cy="4" r="2"/><path d="M3 8l9 2 9-2m-9 2v4m0 0-5 8m5-8 5 8"/>',
    "network": '<rect x="9" y="2" width="6" height="5" rx="1"/><path d="M12 7v4M5 15v-4h14v4"/><rect x="2" y="16" width="6" height="5" rx="1"/><rect x="16" y="16" width="6" height="5" rx="1"/>',
    "appearance": '<circle cx="12" cy="12" r="8"/><path d="M12 4a8 8 0 0 1 0 16Z" fill="currentColor"/>',
    "battle": '<path d="m4 9 3-4 4 2h4l4-2 3 4-2 9-3 1-3-4h-4l-3 4-3-1Z M6 10h5m-2.5-2.5v5m7-2.5h.01m3 2h.01"/>',
    "bt": '<path d="m6 6 12 12-6 4V2l6 4L6 18"/>',
    "btop": '<path d="M3 19V5m0 14h18M6 15l4-5 3 3 7-8"/>',
    "buzz": '<path d="M7 5h10a3 3 0 0 1 3 3v6a3 3 0 0 1-3 3h-5l-6 4v-4a3 3 0 0 1-2-3V8a3 3 0 0 1 3-3Z"/><path d="M8 9h8m-8 4h5"/>',
    "search": '<circle cx="10" cy="10" r="6"/><path d="m14.5 14.5 6 6"/>',
    "terminal": '<path d="m4 6 6 6-6 6m8 0h8"/>',
    "monitor": '<path d="M2 12h5l3-7 4 14 3-7h5"/>',
    "desktop": '<rect x="3" y="4" width="18" height="13" rx="1"/><path d="M12 17v3m-5 0h10"/>',
    "sun": '<circle cx="12" cy="12" r="4"/><path d="M12 1v3m0 16v3M1 12h3m16 0h3M4 4l2 2m12 12 2 2M4 20l2-2M18 6l2-2"/>',
    "music": '<path d="M8 17V5l12-2v12M8 8l12-2"/><ellipse cx="5" cy="18" rx="3" ry="2"/><ellipse cx="17" cy="16" rx="3" ry="2"/>',
    "enter": '<path d="M20 4v9H4m6-6-6 6 6 6"/>',
}


def icon(name):
    return (
        '<svg aria-hidden="true" class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">'
        + ICONS[name]
        + "</svg>"
    )


def header(label, end):
    sym = "terminal" if label == "Command" else "monitor"
    return f'<header><div class="identity">{icon(sym)}<h1>{label}</h1></div><i class="grip"></i><span class="meta">{end}</span></header>'


def query():
    return f'<div class="query">{icon("search")}<span class="caret"></span><span>Type “&gt;” for commands</span></div>'


def foot(kind):
    hints = {
        "launcher": [("↑ ↓", "Select"), ("Enter", "Open"), ("Esc", "Close")],
        "expanded": [("Space", "Collapse"), ("Esc", "Close")],
        "compact": [("Space", "Expand")],
    }[kind]
    return (
        '<div class="keys">'
        + "".join(f"<span><kbd>{k}</kbd> {v}</span>" for k, v in hints)
        + "</div>"
    )


def result_list():
    return (
        '<ol class="results">'
        + "".join(
            f'<li class="{"selected" if i == 0 else ""}"><span class="appicon">{icon(sym)}</span><div class="result-text"><b>{escape(name)}</b><span>{escape(desc)}</span></div><span class="pick" aria-label="Selected">▸</span></li>'
            for i, (sym, name, desc) in enumerate(APPS)
        )
        + "</ol>"
    )


def launcher(d):
    listing, field, title = result_list(), query(), header("Command", "Applications")
    if d == "mission":
        sym, name, desc = APPS[0]
        inspect = f'<aside class="inspect"><small>Inspect selection</small><div class="drawing">{icon(sym)}</div><h2>{name}</h2><p>{desc}</p></aside>'
        body = f'{field}<div class="launch-bays"><section><div class="sectionline"><h3>Results</h3><small>8 applications</small></div>{listing}</section>{inspect}</div>'
    elif d == "sun":
        body = f"{field}{listing}"
    else:
        body = f'{field}<div class="register-head"><span>Application</span><span>Description</span></div>{listing}'
    return f'{title}<div class="launch-body">{body}</div><footer><small>{"Selected 1 of 8" if d != "mission" else "Application browser"}</small>{foot("launcher")}</footer>'


def measures():
    return (
        '<div class="measures">'
        + "".join(
            f'<div class="measure {"missing" if val is None else "valid"}"><small>{name}</small><b>{"—" if val is None else str(val) + "<em>%</em>"}</b></div>'
            for name, val in READINGS
        )
        + "</div>"
    )


def desktop():
    return f'<div class="desktop">{icon("desktop")} Desktop</div>'


def compact(d):
    return f'<div class="compact-assembly">{header("Monitor", "")}{measures()}<div class="compact-context">{desktop()}<small>13:19 local</small></div>{foot("compact")}</div>'


def tabs():
    return (
        '<nav aria-label="Dashboard sections">'
        + "".join(
            f'<span class="{"active" if i == 0 else ""}">{t}</span>'
            for i, t in enumerate(TABS)
        )
        + "</nav>"
    )


def cal():
    # Qt MonthGrid exposes all six weeks, including the prior Sunday row.
    dates = [date(2026, 10, 25) + timedelta(days=offset) for offset in range(42)]
    return (
        '<section class="calendar"><h3>November 2026</h3><div class="dates">'
        + "".join(
            "<small>" + x + "</small>"
            for x in ("Su", "Mo", "Tu", "We", "Th", "Fr", "Sa")
        )
        + "".join(
            f'<span class="{"today" if z.month == 11 and z.day == 22 else "other" if z.month != 11 else ""}">{z.day}</span>'
            for z in dates
        )
        + "</div></section>"
    )


def general():
    return f'<div class="other-data"><section class="local"><small>Local time</small><strong>13:19</strong><p>Sunday, November 22</p></section><section class="weather"><small>Weather</small><strong>{icon("sun")}12<em>°C</em></strong><p>Sunny <span>· Updated 13:19</span></p></section><section class="system"><small>System</small><h3>NixOS 26.11</h3><p>Zokor / niri</p><p>Up 4 days, 3 hours</p></section><section class="media"><small>Media</small><p>{icon("music")}No media</p></section></div>'


def plot(d):
    # Actual capacity percentages; not a fabricated time series or a warning threshold.
    title = "Resource use" if d != "mission" else "Capacity"
    bars = "".join(
        f'<div class="plot-row"><span>{name}</span><div class="track"><i style="width:{val}%"></i></div><b>{val}<em>%</em></b></div>'
        for name, val in READINGS
        if val is not None
    )
    return f'<section class="plot"><div class="plot-title"><h2>{title}</h2><small>Percent used</small></div><div class="bars">{bars}</div><div class="axis"><span>0</span><span>50</span><span>100%</span></div></section>'


def empty_readings():
    return '<div class="unavailable"><small>Unavailable</small><div><span>CPU</span><b>—</b></div><div><span>Audio</span><b>—</b></div></div>'


def expanded(d):
    if d in ("sun", "mission"):
        body = f'<div class="instrument"><div class="instrument-main">{plot(d)}{empty_readings()}</div><div class="instrument-secondary">{general()}{cal()}</div></div>'
    else:
        body = f'<div class="instrument"><section class="glass"><div class="plot-title"><h2>Resource use</h2><small>— Unavailable</small></div>{measures()}</section><div class="instrument-secondary">{cal()}{general()}</div></div>'
    return f'{header("Monitor", "System overview")}<div class="dashboard-body">{tabs()}{body}</div><footer>{desktop()}{foot("expanded")}</footer>'


def document(d, s):
    content = {"launcher": launcher, "compact": compact, "expanded": expanded}[s](d)
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Prototype · {DIRECTIONS[d]} · {STATES[s]}</title><link rel="stylesheet" href="../studies.css"></head><body class="{d} {s}"><main aria-label="Static prototype: {DIRECTIONS[d]}, {STATES[s]}">{content}</main></body></html>'''
