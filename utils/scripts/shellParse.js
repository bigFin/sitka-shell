.pragma library
/*
 * shellParse - pure parsing helpers shared by Sitka Shell services.
 *
 * Everything here is intentionally side-effect free with no Quickshell/Qt
 * dependencies so it runs unmodified under both QML and Node
 * (`node --test tests/`). Ownership of user-facing strings (qsTr),
 * timestamps, and singleton state stays with the calling QML service;
 * these functions only turn raw text into data (or null when the input
 * is missing/malformed, in which case callers keep their prior values).
 */

function stripTerminalCodes(text) {
    const ESC = String.fromCharCode(27);
    const CSI = new RegExp(ESC + "\\[[0-?]*[ -/]*[@-~]", "g");
    const CTRLS = new RegExp("[\\u0000-\\u0008\\u000b\\u000c\\u000e-\\u001f\\u007f]", "g");
    return text.replace(CSI, "").replace(/\r/g, "\n").replace(CTRLS, "");
}

function chooseLongestWindow(snapshot) {
    const primary = snapshot ? snapshot.primary : null;
    const secondary = snapshot ? snapshot.secondary : null;
    if (!primary)
        return secondary;
    if (!secondary)
        return primary;
    return (secondary.windowDurationMins || 0) > (primary.windowDurationMins || 0) ? secondary : primary;
}

function extractCodexQuotas(result) {
    const buckets = (result && result.rateLimitsByLimitId) || {};
    let ids = Object.keys(buckets);
    if (ids.length === 0 && result && result.rateLimits) {
        const fallbackId = result.rateLimits.limitId || "codex";
        buckets[fallbackId] = result.rateLimits;
        ids = [fallbackId];
    }

    const quotas = [];
    for (const id of ids) {
        const snapshot = buckets[id];
        const window = chooseLongestWindow(snapshot);
        if (!window || typeof window.usedPercent !== "number")
            continue;
        quotas.push({
            "id": "codex-" + id,
            "provider": "codex",
            "name": id === "codex" ? "Codex" : (snapshot.limitName || id),
            "usedPercent": Math.max(0, Math.min(100, window.usedPercent)),
            "resetsAt": window.resetsAt ? window.resetsAt * 1000 : 0,
            "resetText": "",
            "plan": snapshot.planType || ""
        });
    }

    quotas.sort((a, b) => a.name === "Codex" ? -1 : (b.name === "Codex" ? 1 : a.name.localeCompare(b.name)));
    return quotas;
}

function extractClaudeQuota(text) {
    const lines = stripTerminalCodes(text).split("\n");

    for (let i = 0; i < lines.length; i++) {
        if (!lines[i].toLowerCase().includes("current week (all models)"))
            continue;

        let percentage = null;
        let resetText = "";
        for (let j = i; j < Math.min(lines.length, i + 8); j++) {
            if (j > i && /current (?:session|week)|extra usage/i.test(lines[j]))
                break;

            const percentageMatch = lines[j].match(/(\d{1,3})%\s*(used|left)/i);
            if (percentageMatch) {
                const value = Number(percentageMatch[1]);
                percentage = percentageMatch[2].toLowerCase() === "left" ? 100 - value : value;
            }

            const resetIndex = lines[j].indexOf("Resets ");
            if (resetIndex >= 0) {
                resetText = lines[j].slice(resetIndex).replace(/\s+\d{1,3}%\s*(?:used|left).*$/i, "").trim();
                const duplicateIndex = resetText.indexOf("Resets ", 7);
                if (duplicateIndex >= 0)
                    resetText = resetText.slice(0, duplicateIndex).trim();
            }
        }

        if (percentage !== null) {
            return {
                "id": "claude",
                "provider": "claude",
                "name": "Claude",
                "usedPercent": Math.max(0, Math.min(100, percentage)),
                "resetsAt": 0,
                "resetText": resetText,
                "plan": ""
            };
        }
    }

    return null;
}

function parseDdcDetectBlock(block) {
    const busMatch = block.match(/I2C bus:\s*\/dev\/i2c-([0-9]+)/);
    const connectorMatch = block.match(/DRM connector:\s+(.*)/);
    if (!busMatch || !connectorMatch)
        return null;
    return {
        busNum: busMatch[1],
        connector: connectorMatch[1].trim().replace(/^card\d+-/, "")
    };
}

function parseMeminfo(text) {
    const totalMatch = text.match(/MemTotal:\s*(\d+)/);
    const availMatch = text.match(/MemAvailable:\s*(\d+)/);
    if (!totalMatch || !availMatch)
        return null;
    const total = parseInt(totalMatch[1], 10) || 1;
    const used = (total - parseInt(availMatch[1], 10)) || 0;
    return {
        total: total,
        used: used
    };
}

function parseNvidiaGpuLine(text) {
    const parts = text.trim().split(",");
    const perc = parseInt(parts[0], 10) / 100;
    const temp = parseInt(parts[1], 10);
    if (isNaN(perc) || isNaN(temp))
        return null;
    return {
        perc: perc,
        temp: temp
    };
}

function parseGenericGpuLines(text) {
    const values = text.trim().split("\n").filter(d => d !== "").map(d => parseInt(d, 10)).filter(v => !isNaN(v));
    if (values.length === 0)
        return null;
    return values.reduce((acc, v) => acc + v, 0) / values.length / 100;
}

function nearlyEqual(a, b) {
    return Math.abs((a || 0) - (b || 0)) < 0.0001;
}

function formatKib(kib) {
    const mib = 1024;
    const gib = 1024 * 1024;
    const tib = 1024 * 1024 * 1024;

    if (kib >= tib)
        return {
            value: kib / tib,
            unit: "TiB"
        };
    if (kib >= gib)
        return {
            value: kib / gib,
            unit: "GiB"
        };
    if (kib >= mib)
        return {
            value: kib / mib,
            unit: "MiB"
        };
    return {
        value: kib,
        unit: "KiB"
    };
}

function calculateCpuUsage(currentStats, lastStats) {
    if (!lastStats || !currentStats || currentStats.length < 4) {
        return 0;
    }

    const currentTotal = currentStats.reduce((sum, val) => sum + val, 0);
    const lastTotal = lastStats.reduce((sum, val) => sum + val, 0);

    const totalDiff = currentTotal - lastTotal;
    if (totalDiff <= 0)
        return 0;

    const currentIdle = currentStats[3];
    const lastIdle = lastStats[3];
    const idleDiff = currentIdle - lastIdle;

    const usedDiff = totalDiff - idleDiff;
    return Math.max(0, Math.min(100, (usedDiff / totalDiff) * 100));
}

function coalesceWindowEvents(events, closedType, openedType) {
    const byType = {};
    const windowUpserts = {};
    const ordered = [];

    for (let i = 0; i < events.length; i++) {
        const event = events[i];
        const type = event.type;

        if (type === closedType) {
            const closedId = event.data ? event.data.id : undefined;
            if (closedId !== undefined && closedId !== null)
                delete windowUpserts[closedId];
            ordered.push(event);
        } else if (type === openedType) {
            const windowId = event.data && event.data.window ? event.data.window.id : undefined;
            if (windowId === undefined || windowId === null) {
                ordered.push(event);
            } else {
                windowUpserts[windowId] = event;
            }
        } else {
            byType[type] = event;
        }
    }

    for (const windowId in windowUpserts) {
        ordered.push(windowUpserts[windowId]);
    }
    for (const type in byType) {
        ordered.push(byType[type]);
    }

    return ordered;
}

function buildProcessRows(processes) {
    const rows = [];
    for (const proc of processes || []) {
        rows.push({
            "pid": proc.pid,
            "ppid": proc.ppid,
            "cpu": proc.cpu,
            "memoryPercent": proc.memoryPercent,
            "memoryKB": proc.memoryKB,
            "command": proc.command,
            "fullCommand": proc.fullCommand,
            "displayName": proc.command.length > 15 ? proc.command.substring(0, 15) + "..." : proc.command
        });
    }
    return rows;
}

function shouldWarnOverflow(nowMs, lastWarnMs) {
    return nowMs - lastWarnMs > 1000;
}

function cleanWindowText(value) {
    if (!value)
        return "";
    // Strip leading control/format characters (C0/C1, bidi isolates and
    // overrides, BOM) while preserving legitimate leading text such as
    // CJK characters or emoji. Built from code points so this file stays
    // pure ASCII.
    const formats = [0x200E, 0x200F, 0x202A, 0x202B, 0x202C, 0x202D, 0x202E, 0x2066, 0x2067, 0x2068, 0x2069, 0xFEFF];
    let i = 0;
    while (i < value.length) {
        const c = value.charCodeAt(i);
        const control = c < 0x20 || (c >= 0x7F && c <= 0x9F);
        if (!control && formats.indexOf(c) < 0)
            break;
        i++;
    }
    return value.slice(i);
}

function isRequestStale(nowMs, sentMs, timeoutMs) {
    return nowMs - sentMs > timeoutMs;
}

function getLuminance(c) {
    if (c.r == 0 && c.g == 0 && c.b == 0)
        return 0;
    return Math.sqrt(0.299 * Math.pow(c.r, 2) + 0.587 * Math.pow(c.g, 2) + 0.114 * Math.pow(c.b, 2));
}

function clamp01(v) {
    return Math.max(0, Math.min(1, v));
}

function parseNmcliNetworks(text) {
    const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
    const rows = [];

    for (const line of text.trim().split("\n")) {
        if (!line)
            continue;
        const net = line.replace(/\\:/g, PLACEHOLDER).split(":");
        const strength = parseInt(net[1], 10);
        const frequency = parseInt(net[2], 10);
        const ssid = (net[3] || "").split(PLACEHOLDER).join(":");
        if (!ssid)
            continue;
        rows.push({
            active: net[0] === "yes",
            strength: Number.isFinite(strength) ? strength : 0,
            frequency: Number.isFinite(frequency) ? frequency : 0,
            ssid: ssid,
            bssid: (net[4] || "").split(PLACEHOLDER).join(":"),
            security: net[5] || ""
        });
    }

    return rows;
}

function getProcessIcon(command) {
    const cmd = command.toLowerCase();
    if (cmd.includes("firefox") || cmd.includes("chrome") || cmd.includes("browser"))
        return "web";
    if (cmd.includes("code") || cmd.includes("editor") || cmd.includes("vim"))
        return "code";
    if (cmd.includes("terminal") || cmd.includes("bash") || cmd.includes("zsh"))
        return "terminal";
    if (cmd.includes("music") || cmd.includes("audio") || cmd.includes("spotify"))
        return "music_note";
    if (cmd.includes("video") || cmd.includes("vlc") || cmd.includes("mpv"))
        return "play_circle";
    if (cmd.includes("systemd") || cmd.includes("kernel") || cmd.includes("kthread"))
        return "settings";
    return "memory";
}

function formatCpuUsage(cpu) {
    return (cpu || 0).toFixed(1) + "%";
}

function formatMemoryUsage(memoryKB) {
    const mem = memoryKB || 0;
    if (mem < 1024)
        return mem.toFixed(0) + " KB";
    else if (mem < 1024 * 1024)
        return (mem / 1024).toFixed(1) + " MB";
    else
        return (mem / (1024 * 1024)).toFixed(1) + " GB";
}

function formatSystemMemory(memoryKB) {
    const mem = memoryKB || 0;
    if (mem < 1024 * 1024)
        return (mem / 1024).toFixed(0) + " MB";
    else
        return (mem / (1024 * 1024)).toFixed(1) + " GB";
}

function sameWorkspaceList(a, b) {
    if (a.length !== b.length)
        return false;

    for (let i = 0; i < a.length; i++) {
        const left = a[i];
        const right = b[i];
        if (left.id !== right.id || left.idx !== right.idx || left.name !== right.name || left.output !== right.output || left.is_active !== right.is_active || left.is_focused !== right.is_focused || left.windowCount !== right.windowCount)
            return false;
    }
    return true;
}

function sameOccupancy(a, b) {
    const aKeys = Object.keys(a);
    const bKeys = Object.keys(b);
    if (aKeys.length !== bKeys.length)
        return false;

    for (let i = 0; i < aKeys.length; i++) {
        const key = aKeys[i];
        if (a[key] !== b[key])
            return false;
    }
    return true;
}

function sameSnapshot(a, b) {
    return a.focusedWorkspaceId === b.focusedWorkspaceId && a.focusedWorkspaceIndex === b.focusedWorkspaceIndex && a.focusedMonitorName === b.focusedMonitorName && sameWorkspaceList(a.allWorkspaces, b.allWorkspaces) && sameOccupancy(a.workspaceHasWindows, b.workspaceHasWindows);
}

function sameFocusIdentity(a, b) {
    return a.hasWindow === b.hasWindow && a.id === b.id;
}

function sameWindowInfo(a, b) {
    return a.hasWindow === b.hasWindow
        && a.id === b.id
        && a.appId === b.appId
        && a.title === b.title
        && a.rawTitle === b.rawTitle
        && a.detailKey === b.detailKey;
}

function detailKeyFromStoreWindow(win) {
    return [
        win.id,
        win.workspaceId,
        win.pid,
        win.appId,
        win.title,
        win.isFloating,
        win.isUrgent,
        win.layoutCol,
        win.layoutRow,
        win.tilePosX,
        win.tilePosY,
        win.width,
        win.height
    ].join("|");
}
