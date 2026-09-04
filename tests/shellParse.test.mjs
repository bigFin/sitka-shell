// Sitka Shell pure-logic tests. No dependencies: `node --test tests/`
// Loads utils/scripts/shellParse.js (a QML `.pragma library`) by stripping
// the pragma line, so the exact file the shell ships is what gets tested.

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const src = readFileSync(path.join(root, "utils/scripts/shellParse.js"), "utf8")
    .split("\n")
    .filter(l => !l.startsWith(".pragma"))
    .join("\n");

// Run in this realm (not a fresh vm context) so deepStrictEqual sees
// objects with the standard Object prototype.
vm.runInThisContext(src + `;globalThis.__shellParse = {
    stripTerminalCodes, chooseLongestWindow, extractCodexQuotas,
    extractClaudeQuota, parseDdcDetectBlock, parseMeminfo,
    parseNvidiaGpuLine, parseGenericGpuLines, nearlyEqual,
    formatKib, calculateCpuUsage, coalesceWindowEvents,
    buildProcessRows, shouldWarnOverflow, cleanWindowText, isRequestStale,
    getLuminance, clamp01, parseNmcliNetworks,
    getProcessIcon, formatCpuUsage, formatMemoryUsage, formatSystemMemory,
    sameSnapshot, sameWorkspaceList, sameOccupancy,
    sameFocusIdentity, sameWindowInfo, detailKeyFromStoreWindow,
    detailKeyFromClient, clientFromStoreWindow
}`, { filename: "shellParse.js" });
const api = globalThis.__shellParse;
delete globalThis.__shellParse;

describe("parseDdcDetectBlock", () => {
    it("parses bus and strips the card prefix from the connector", () => {
        assert.deepEqual(api.parseDdcDetectBlock("Display 1\nI2C bus:  /dev/i2c-3\nDRM connector:  card1-DP-2"), {
            busNum: "3",
            connector: "DP-2"
        });
    });

    it("keeps connectors without a card prefix untouched", () => {
        assert.equal(api.parseDdcDetectBlock("Display 1\nI2C bus: /dev/i2c-9\nDRM connector: HDMI-A-1").connector, "HDMI-A-1");
    });

    it("drops blocks missing either field instead of throwing", () => {
        assert.equal(api.parseDdcDetectBlock("Display 1\nDRM connector: card0-DP-1"), null);
        assert.equal(api.parseDdcDetectBlock("Display 1\nI2C bus: /dev/i2c-3"), null);
        assert.equal(api.parseDdcDetectBlock("garbage"), null);
    });
});

describe("parseMeminfo", () => {
    it("computes used from total minus available", () => {
        assert.deepEqual(api.parseMeminfo("MemTotal:        16384000 kB\nMemAvailable:     8192000 kB\n"), {
            total: 16384000,
            used: 8192000
        });
    });

    it("returns null when the read is empty or truncated", () => {
        assert.equal(api.parseMeminfo(""), null);
        assert.equal(api.parseMeminfo("MemTotal: 16384000 kB\n"), null);
        assert.equal(api.parseMeminfo("nonsense"), null);
    });
});

describe("parseNvidiaGpuLine", () => {
    it("parses utilization and temperature", () => {
        assert.deepEqual(api.parseNvidiaGpuLine("42, 61"), { perc: 0.42, temp: 61 });
    });

    it("returns null on driver errors instead of NaN", () => {
        assert.equal(api.parseNvidiaGpuLine(""), null);
        assert.equal(api.parseNvidiaGpuLine("N/A, N/A"), null);
        assert.equal(api.parseNvidiaGpuLine("42"), null);
    });
});

describe("parseGenericGpuLines", () => {
    it("averages per-card busy percent files", () => {
        assert.equal(api.parseGenericGpuLines("20\n40\n"), 0.3);
    });

    it("ignores unreadable lines but keeps valid ones", () => {
        assert.equal(api.parseGenericGpuLines("50\nERR\n"), 0.5);
    });

    it("returns null when nothing parses", () => {
        assert.equal(api.parseGenericGpuLines(""), null);
        assert.equal(api.parseGenericGpuLines("ERR\n"), null);
    });
});

describe("stripTerminalCodes", () => {
    it("strips ANSI escapes, carriage returns, and control chars", () => {
        assert.equal(api.stripTerminalCodes("\u001b[1m42%\u001b[0m used\r\n"), "42% used\n\n");
        assert.equal(api.stripTerminalCodes("a" + String.fromCharCode(7) + "b"), "ab");
    });
});

describe("chooseLongestWindow", () => {
    it("picks the longer window and tolerates missing halves", () => {
        const primary = { windowDurationMins: 60 };
        const secondary = { windowDurationMins: 10080 };
        assert.equal(api.chooseLongestWindow({ primary, secondary }), secondary);
        assert.equal(api.chooseLongestWindow({ primary }), primary);
        assert.equal(api.chooseLongestWindow({ secondary }), secondary);
        assert.equal(api.chooseLongestWindow(null), null);
    });
});

describe("extractCodexQuotas", () => {
    it("keeps the longest window per limit id", () => {
        const quotas = api.extractCodexQuotas({
            rateLimitsByLimitId: {
                codex: {
                    limitName: "Codex",
                    primary: { usedPercent: 10, windowDurationMins: 60 },
                    secondary: { usedPercent: 75, windowDurationMins: 10080, resetsAt: 1700000000 }
                }
            }
        });
        assert.equal(quotas.length, 1);
        assert.equal(quotas[0].usedPercent, 75);
        assert.equal(quotas[0].resetsAt, 1700000000000);
    });

    it("falls back to a lone rateLimits snapshot and sorts Codex first", () => {
        const quotas = api.extractCodexQuotas({
            rateLimitsByLimitId: {
                zzz: { limitName: "zzz", primary: { usedPercent: 5, windowDurationMins: 60 } }
            },
            rateLimits: null
        });
        assert.deepEqual(quotas.map(q => q.id), ["codex-zzz"]);
    });

    it("clamps percentages and skips windows without numbers", () => {
        const quotas = api.extractCodexQuotas({
            rateLimitsByLimitId: {
                a: { primary: { usedPercent: 150, windowDurationMins: 60 } },
                b: { primary: { windowDurationMins: 60 } }
            }
        });
        assert.deepEqual(quotas.map(q => q.usedPercent), [100]);
    });

    it("returns an empty array when nothing is reported", () => {
        assert.deepEqual(api.extractCodexQuotas({}), []);
        assert.deepEqual(api.extractCodexQuotas(null), []);
    });
});

describe("extractClaudeQuota", () => {
    it("reads a used percentage with reset text", () => {
        const quota = api.extractClaudeQuota("Current week (all models)\n  42% used\n  Resets Sep 10");
        assert.equal(quota.usedPercent, 42);
        assert.equal(quota.resetText, "Resets Sep 10");
    });

    it("converts percent-left into percent-used", () => {
        assert.equal(api.extractClaudeQuota("Current week (all models)\n  30% left").usedPercent, 70);
    });

    it("returns null when no weekly quota is present", () => {
        assert.equal(api.extractClaudeQuota("nothing here"), null);
    });
});

describe("nearlyEqual", () => {
    it("compares with a 1e-4 epsilon", () => {
        assert.equal(api.nearlyEqual(0.5, 0.50005), true);
        assert.equal(api.nearlyEqual(0.5, 0.51), false);
        assert.equal(api.nearlyEqual(undefined, 0), true);
    });
});

describe("formatKib", () => {
    it("picks units at exact boundaries", () => {
        assert.deepEqual(api.formatKib(512), { value: 512, unit: "KiB" });
        assert.deepEqual(api.formatKib(2048), { value: 2, unit: "MiB" });
        assert.deepEqual(api.formatKib(2 * 1024 * 1024), { value: 2, unit: "GiB" });
        assert.deepEqual(api.formatKib(2 * 1024 * 1024 * 1024), { value: 2, unit: "TiB" });
    });
});

describe("calculateCpuUsage", () => {
    it("returns 0 without a previous sample or on short input", () => {
        assert.equal(api.calculateCpuUsage([1, 2, 3, 4, 5, 6, 7, 8], null), 0);
        assert.equal(api.calculateCpuUsage([1, 2, 3], [1, 2, 3]), 0);
        assert.equal(api.calculateCpuUsage([1, 1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1, 1]), 0);
    });

    it("measures the busy fraction between samples", () => {
        // total +100, idle +20 -> 80% busy
        assert.equal(api.calculateCpuUsage([110, 0, 50, 820, 0, 0, 0, 0], [50, 0, 30, 800, 0, 0, 0, 0]), 80);
    });
});

describe("coalesceWindowEvents", () => {
    const CLOSED = "window_closed";
    const OPENED = "window_opened";
    const open = id => ({ type: OPENED, data: { window: { id } } });
    const close = id => ({ type: CLOSED, data: { id } });

    it("merges repeat upserts for one window, keeping the latest", () => {
        const out = api.coalesceWindowEvents([open(1), open(1)], CLOSED, OPENED);
        assert.equal(out.length, 1);
        assert.equal(out[0].data.window.id, 1);
    });

    it("lets a close in the same batch kill its earlier upsert", () => {
        const out = api.coalesceWindowEvents([open(1), close(1)], CLOSED, OPENED);
        assert.deepEqual(out.map(e => e.type), [CLOSED]);
    });

    it("lets a later open win after a close", () => {
        const out = api.coalesceWindowEvents([close(1), open(1)], CLOSED, OPENED);
        assert.deepEqual(out.map(e => e.type), [CLOSED, OPENED]);
    });

    it("keeps closes ordered and other types latest-wins", () => {
        const a = { type: "workspaces_changed", data: { v: 1 } };
        const b = { type: "workspaces_changed", data: { v: 2 } };
        const out = api.coalesceWindowEvents([close(1), a, close(2), b], CLOSED, OPENED);
        assert.deepEqual(out.map(e => e.type), [CLOSED, CLOSED, "workspaces_changed"]);
        assert.equal(out[2].data.v, 2);
    });
});

describe("buildProcessRows", () => {
    it("projects fields and truncates long commands", () => {
        const rows = api.buildProcessRows([
            { pid: 1, ppid: 0, cpu: 2.5, memoryPercent: 1.1, memoryKB: 2048, command: "quickshell-with-a-long-name", fullCommand: "/bin/quickshell" },
            { pid: 2, ppid: 1, cpu: 0, memoryPercent: 0.1, memoryKB: 512, command: "sh", fullCommand: "sh" }
        ]);
        assert.equal(rows.length, 2);
        assert.equal(rows[0].displayName, "quickshell-with...");
        assert.equal(rows[1].displayName, "sh");
        assert.equal(rows[0].cpu, 2.5);
    });
    it("returns an empty array for missing input", () => {
        assert.deepEqual(api.buildProcessRows(null), []);
        assert.deepEqual(api.buildProcessRows([]), []);
});
});

describe("shouldWarnOverflow", () => {
    it("throttles repeat warnings to one per second", () => {
        assert.equal(api.shouldWarnOverflow(1500, 0), true);
        assert.equal(api.shouldWarnOverflow(500, 0), false);
        assert.equal(api.shouldWarnOverflow(1000, 0), false);
    });
});

describe("cleanWindowText", () => {
    const BEL = String.fromCharCode(7);
    const RLM = String.fromCharCode(0x200F);
    const BOM = String.fromCharCode(0xFEFF);
    const CJK = String.fromCharCode(0x4E2D);
    const EMOJI = String.fromCodePoint(0x1F525);

    it("strips leading control and bidi formatting", () => {
        assert.equal(api.cleanWindowText(BEL + "Title"), "Title");
        assert.equal(api.cleanWindowText(RLM + "Title"), "Title");
        assert.equal(api.cleanWindowText(BOM + "Title"), "Title");
    });

    it("preserves legitimate leading text and spaces", () => {
        assert.equal(api.cleanWindowText(CJK + "Neovim"), CJK + "Neovim");
        assert.equal(api.cleanWindowText(EMOJI + "Firefox"), EMOJI + "Firefox");
        assert.equal(api.cleanWindowText(" Leading space"), " Leading space");
        assert.equal(api.cleanWindowText(""), "");
    });
});

describe("isRequestStale", () => {
    it("flags requests older than the timeout", () => {
        assert.equal(api.isRequestStale(121000, 0, 120000), true);
        assert.equal(api.isRequestStale(60000, 0, 120000), false);
        assert.equal(api.isRequestStale(120000, 0, 120000), false);
    });
});

describe("getLuminance", () => {
    it("returns 0 for black and perceptual weights otherwise", () => {
        assert.equal(api.getLuminance({ r: 0, g: 0, b: 0 }), 0);
        assert.ok(api.nearlyEqual(api.getLuminance({ r: 1, g: 1, b: 1 }), 1));
        const red = api.getLuminance({ r: 1, g: 0, b: 0 });
        const green = api.getLuminance({ r: 0, g: 1, b: 0 });
        const blue = api.getLuminance({ r: 0, g: 0, b: 1 });
        assert.ok(green > red && red > blue);
    });
});

describe("clamp01", () => {
    it("clamps outside values and passes through inside ones", () => {
        assert.equal(api.clamp01(-0.5), 0);
        assert.equal(api.clamp01(1.5), 1);
        assert.equal(api.clamp01(0.42), 0.42);
    });
});

describe("parseNmcliNetworks", () => {
    it("parses escaped rows with BSSID colons restored", () => {
        const rows = api.parseNmcliNetworks("yes:80:5180:MyNet:AA\\:BB\\:CC\\:DD\\:EE\\:FF:WPA2");
        assert.equal(rows.length, 1);
        assert.deepEqual(rows[0], {
            active: true,
            strength: 80,
            frequency: 5180,
            ssid: "MyNet",
            bssid: "AA:BB:CC:DD:EE:FF",
            security: "WPA2"
        });
    });

    it("restores escaped colons inside SSIDs", () => {
        const rows = api.parseNmcliNetworks("no:60:2412:My\\:Net:11\\:22\\:33\\:44\\:55\\:66:--");
        assert.equal(rows[0].ssid, "My:Net");
        assert.equal(rows[0].bssid, "11:22:33:44:55:66");
    });

    it("drops empty and truncated rows and zeroes bad numbers", () => {
        assert.deepEqual(api.parseNmcliNetworks(""), []);
        assert.deepEqual(api.parseNmcliNetworks("garbage"), []);
        const rows = api.parseNmcliNetworks("no:xx:yy:Net:AA:--");
        assert.equal(rows[0].strength, 0);
        assert.equal(rows[0].frequency, 0);
    });
});

describe("getProcessIcon", () => {
    it("maps well-known commands and falls back to memory", () => {
        assert.equal(api.getProcessIcon("firefox"), "web");
        assert.equal(api.getProcessIcon("Code"), "code");
        assert.equal(api.getProcessIcon("foot"), "memory");
        assert.equal(api.getProcessIcon("systemd-journald"), "settings");
    });
});

describe("formatCpuUsage", () => {
    it("renders one decimal with a percent sign", () => {
        assert.equal(api.formatCpuUsage(12.34), "12.3%");
        assert.equal(api.formatCpuUsage(null), "0.0%");
    });
});

describe("formatMemoryUsage", () => {
    it("picks units at exact boundaries", () => {
        assert.equal(api.formatMemoryUsage(512), "512 KB");
        assert.equal(api.formatMemoryUsage(2048), "2.0 MB");
        assert.equal(api.formatMemoryUsage(2 * 1024 * 1024), "2.0 GB");
    });
});

describe("formatSystemMemory", () => {
    it("renders megabytes whole and gigabytes with decimals", () => {
        assert.equal(api.formatSystemMemory(2048), "2 MB");
        assert.equal(api.formatSystemMemory(3 * 1024 * 1024), "3.0 GB");
    });
});

describe("sameWorkspaceList", () => {
    const ws = id => ({ id, idx: 1, name: "code", output: "DP-1", is_active: true, is_focused: true, windowCount: 2 });

    it("compares field by field in order", () => {
        assert.equal(api.sameWorkspaceList([ws(1)], [ws(1)]), true);
        assert.equal(api.sameWorkspaceList([ws(1)], [ws(2)]), false);
        assert.equal(api.sameWorkspaceList([ws(1)], []), false);
        assert.equal(api.sameWorkspaceList([ws(1)], [{ ...ws(1), windowCount: 3 }]), false);
    });
});

describe("sameOccupancy", () => {
    it("compares occupancy maps regardless of insertion order", () => {
        assert.equal(api.sameOccupancy({ 1: true, 2: false }, { 2: false, 1: true }), true);
        assert.equal(api.sameOccupancy({ 1: true }, { 1: false }), false);
        assert.equal(api.sameOccupancy({ 1: true }, {}), false);
    });
});

describe("sameSnapshot", () => {
    const snap = () => ({
        focusedWorkspaceId: "1",
        focusedWorkspaceIndex: 0,
        focusedMonitorName: "DP-1",
        allWorkspaces: [{ id: 1, idx: 1, name: "code", output: "DP-1", is_active: true, is_focused: true, windowCount: 2 }],
        workspaceHasWindows: { 1: true }
    });

    it("detects focus, list, and occupancy changes", () => {
        assert.equal(api.sameSnapshot(snap(), snap()), true);
        assert.equal(api.sameSnapshot({ ...snap(), focusedWorkspaceId: "2" }, snap()), false);
        assert.equal(api.sameSnapshot({ ...snap(), workspaceHasWindows: {} }, snap()), false);
    });
});

describe("sameFocusIdentity", () => {
    it("ignores detail-only changes", () => {
        const a = { hasWindow: true, id: "1", title: "old" };
        assert.equal(api.sameFocusIdentity(a, { ...a }), true);
        assert.equal(api.sameFocusIdentity(a, { ...a, title: "new" }), true);
        assert.equal(api.sameFocusIdentity(a, { ...a, id: "2" }), false);
        assert.equal(api.sameFocusIdentity(a, { hasWindow: false, id: "1" }), false);
    });
});

describe("sameWindowInfo", () => {
    const info = () => ({ hasWindow: true, id: "1", appId: "foot", title: "t", rawTitle: "t", detailKey: "k" });

    it("catches any display-relevant change", () => {
        assert.equal(api.sameWindowInfo(info(), info()), true);
        assert.equal(api.sameWindowInfo(info(), { ...info(), title: "other" }), false);
        assert.equal(api.sameWindowInfo(info(), { ...info(), detailKey: "other" }), false);
    });
});

describe("detailKeyFromStoreWindow", () => {
    it("joins identifying fields in stable order", () => {
        const key = api.detailKeyFromStoreWindow({
            id: 7, workspaceId: 2, pid: 100, appId: "foot", title: "t",
            isFloating: false, isUrgent: false, layoutCol: 0, layoutRow: 1,
            tilePosX: -1, tilePosY: -1, width: 800, height: 600
        });
        assert.equal(key, "7|2|100|foot|t|false|false|0|1|-1|-1|800|600");
    });
});

describe("detailKeyFromClient", () => {
    it("falls back across Hypr and Niri field shapes", () => {
        assert.equal(api.detailKeyFromClient(null), "");
        const key = api.detailKeyFromClient({
            id: "0xabc", workspace_id: 3, pid: 9, class: "foot",
            title: "t", floating: true,
            layout: { pos_in_scrolling_layout: [1, 0], window_size: [800, 600] }
        });
        assert.equal(key, "0xabc|3|9|foot|t|true|false|1|0|||800|600");
    });
});

describe("clientFromStoreWindow", () => {
    it("projects store fields and nulls negative tile positions", () => {
        const client = api.clientFromStoreWindow({
            id: 7, workspaceId: 2, pid: 1, appId: "foot", title: "t",
            isFocused: true, isFloating: false, isUrgent: false,
            layoutCol: 0, layoutRow: 1, tilePosX: -1, tilePosY: -1,
            width: 800, height: 600
        });
        assert.equal(client.workspace_id, 2);
        assert.equal(client.layout.tile_pos_in_workspace_view, null);
        assert.deepEqual(client.layout.window_size, [800, 600]);
    });
});
