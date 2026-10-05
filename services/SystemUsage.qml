pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQuick
import "../utils/scripts/shellParse.js" as ShellParse
import "../utils/scripts/cpuSampling.js" as CpuSampling
import qs.services
import "../utils/scripts/dashboardData.js" as DashboardData

Singleton {
    id: root

    property var cpuState: DashboardData.initial()
    property var memoryState: DashboardData.initial()
    property var storageState: DashboardData.initial()

    function updateState(domain: string, outcome: string): void {
        const key = domain + "State";
        let next = DashboardData.transition(root[key], outcome, Date.now());
        // An in-flight read may finish after the last consumer leaves or idle
        // begins. Keep its value/timestamp, but never clear paused staleness.
        if (!root[domain + "Active"] || IdleService.isIdle)
            next = DashboardData.transition(next, "paused", Date.now());
        root[key] = next;
    }

    Connections {
        target: IdleService
        function onIsIdleChanged(): void {
            if (IdleService.isIdle) {
                root.updateState("cpu", "paused");
                root.updateState("memory", "paused");
                root.updateState("storage", "paused");
            }
        }
    }

    onCpuActiveChanged: { if (!cpuActive) updateState("cpu", "paused"); }
    onMemoryActiveChanged: { if (!memoryActive) updateState("memory", "paused"); }
    onStorageActiveChanged: { if (!storageActive) updateState("storage", "paused"); }

    property real cpuPerc
    property real cpuTemp
    readonly property string gpuType: (Config.services.gpuType || "").toUpperCase() || autoGpuType
    property string autoGpuType: "NONE"
    property real gpuPerc
    property real gpuTemp
    property real memUsed
    property real memTotal
    readonly property real memPerc: memTotal > 0 ? memUsed / memTotal : 0
    property real storageUsed
    property real storageTotal
    property real storagePerc: storageTotal > 0 ? storageUsed / storageTotal : 0

    property real lastCpuIdle
    property real lastCpuTotal
    property var cpuSample: null

    property int refCount
    property int domainRefCount
    property int cpuRefCount
    property int memoryRefCount
    property int storageRefCount
    property int gpuRefCount
    property int sensorRefCount

    readonly property int legacyRefCount: Math.max(0, refCount - domainRefCount)
    readonly property bool cpuActive: legacyRefCount > 0 || cpuRefCount > 0
    readonly property bool memoryActive: legacyRefCount > 0 || memoryRefCount > 0
    readonly property bool storageActive: legacyRefCount > 0 || storageRefCount > 0
    readonly property bool gpuActive: legacyRefCount > 0 || gpuRefCount > 0
    readonly property bool sensorActive: legacyRefCount > 0 || sensorRefCount > 0

    property int cpuSerial
    property int memorySerial
    property int storageSerial
    property int gpuSerial
    property int sensorSerial

    property int cpuPollCount
    property int memoryPollCount
    property int storagePollCount
    property int gpuPollCount
    property int sensorPollCount

    function formatKib(kib: real): var {
        return ShellParse.formatKib(kib);
    }

    function addRef(domains: var): void {
        const refs = normaliseDomains(domains);
        refCount++;
        domainRefCount++;
        adjustDomainRefs(refs, 1);
    }

    function removeRef(domains: var): void {
        const refs = normaliseDomains(domains);
        refCount = Math.max(0, refCount - 1);
        domainRefCount = Math.max(0, domainRefCount - 1);
        adjustDomainRefs(refs, -1);
    }

    function normaliseDomains(domains: var): var {
        if (!domains)
            return ["cpu", "memory", "storage", "gpu", "sensors"];
        if (typeof domains === "string")
            return [domains];
        return domains;
    }

    function adjustDomainRefs(domains: var, delta: int): void {
        for (let i = 0; i < domains.length; i++) {
            switch (domains[i]) {
            case "cpu":
                cpuRefCount = Math.max(0, cpuRefCount + delta);
                break;
            case "memory":
                memoryRefCount = Math.max(0, memoryRefCount + delta);
                break;
            case "storage":
                storageRefCount = Math.max(0, storageRefCount + delta);
                break;
            case "gpu":
                gpuRefCount = Math.max(0, gpuRefCount + delta);
                break;
            case "sensors":
                sensorRefCount = Math.max(0, sensorRefCount + delta);
                break;
            }
        }
    }

    function nearlyEqual(a: real, b: real): bool {
        return ShellParse.nearlyEqual(a, b);
    }

    function pollCpu(): void {
        updateState("cpu", "loading");
        cpuPollCount++;
        stat.reload();
    }

    function pollMemory(): void {
        updateState("memory", "loading");
        memoryPollCount++;
        meminfo.reload();
    }

    function pollStorage(): void {
        if (storage.running)
            return;
        updateState("storage", "loading");
        storagePollCount++;
        storage.streamReady = false;
        storage.exitReady = false;
        storage.running = true;
    }

    function pollGpu(): void {
        if (gpuUsage.running)
            return;
        if (root.gpuType !== "GENERIC" && root.gpuType !== "NVIDIA") {
            if (!root.nearlyEqual(root.gpuPerc, 0) || !root.nearlyEqual(root.gpuTemp, 0)) {
                root.gpuPerc = 0;
                root.gpuTemp = 0;
                root.gpuSerial++;
            }
            return;
        }
        gpuPollCount++;
        gpuUsage.running = true;
    }

    function pollSensors(): void {
        if (sensors.running)
            return;
        sensorPollCount++;
        sensors.running = true;
    }

    Timer {
        running: root.cpuActive && !IdleService.isIdle
        onRunningChanged: root.cpuSample = null
        interval: 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollCpu()
    }

    Timer {
        running: root.memoryActive && !IdleService.isIdle
        interval: 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollMemory()
    }

    Timer {
        running: root.storageActive && !IdleService.isIdle
        interval: 15000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollStorage()
    }

    Timer {
        running: root.gpuActive && !IdleService.isIdle
        interval: 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollGpu()
    }

    Timer {
        running: root.sensorActive && !IdleService.isIdle
        interval: 10000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollSensors()
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoadFailed: root.updateState("cpu", "failure")
        onLoaded: {
            if (!root.cpuActive || IdleService.isIdle) {
                root.cpuSample = null;
                return;
            }
            const result = CpuSampling.sample(text(), root.cpuSample, Date.now(), ShellParse.calculateCpuUsage);
            root.cpuSample = result.previous;
            root.updateState("cpu", result.usage !== null ? "success" : "failure");
            if (result.previous) {
                root.lastCpuTotal = result.previous.stats.reduce((a, b) => a + b, 0);
                root.lastCpuIdle = result.previous.stats[3];
            }
            if (result.usage !== null && !root.nearlyEqual(root.cpuPerc, result.usage)) {
                root.cpuPerc = result.usage;
                root.cpuSerial++;
            }
        }
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoadFailed: root.updateState("memory", "failure")
        onLoaded: {
            const data = text();
            const parsed = ShellParse.parseMeminfo(data);
            root.updateState("memory", parsed ? "success" : "failure");
            if (!parsed)
                return;
            const nextMemTotal = parsed.total;
            const nextMemUsed = parsed.used;
            if (!root.nearlyEqual(root.memTotal, nextMemTotal) || !root.nearlyEqual(root.memUsed, nextMemUsed)) {
                root.memTotal = nextMemTotal;
                root.memUsed = nextMemUsed;
                root.memorySerial++;
            }
        }
    }

    Process {
        id: storage

        property bool streamReady: false
        property bool exitReady: false
        property bool succeeded: false
        property string output

        onExited: (exitCode, exitStatus) => {
            succeeded = exitCode === 0 && exitStatus === 0;
            exitReady = true;
            publish();
        }

        command: ["sh", "-c", "df | grep '^/dev/' | awk '{print $1, $3, $4}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                storage.output = text;
                storage.streamReady = true;
                storage.publish();
            }
        }

        // Process exit and stream completion can arrive in either order.
        function publish(): void {
            if (!streamReady || !exitReady)
                return;
            streamReady = false;
            exitReady = false;
            if (!succeeded) {
                root.updateState("storage", "failure");
                return;
            }
            const deviceMap = new Map();

            for (const line of output.trim().split("\n")) {
                if (line.trim() === "")
                    continue;

                const parts = line.trim().split(/\s+/);
                if (parts.length >= 3) {
                    const device = parts[0];
                    const used = Number(parts[1]);
                    const avail = Number(parts[2]);

                    if (!Number.isFinite(used) || !Number.isFinite(avail) || used < 0 || avail < 0)
                        continue;

                    // Only keep the entry with the largest total space for each device
                    if (!deviceMap.has(device) || (used + avail) > (deviceMap.get(device).used + deviceMap.get(device).avail)) {
                        deviceMap.set(device, {
                            used: used,
                            avail: avail
                        });
                    }
                }
            }

            let totalUsed = 0;
            let totalAvail = 0;

            for (const [device, stats] of deviceMap) {
                totalUsed += stats.used;
                totalAvail += stats.avail;
            }

            const nextStorageTotal = totalUsed + totalAvail;
            root.updateState("storage", nextStorageTotal > 0 ? "success" : "failure");
            if (nextStorageTotal <= 0)
                return;
            if (!root.nearlyEqual(root.storageUsed, totalUsed) || !root.nearlyEqual(root.storageTotal, nextStorageTotal)) {
                root.storageUsed = totalUsed;
                root.storageTotal = nextStorageTotal;
                root.storageSerial++;
            }
        }
    }

    Process {
        id: gpuTypeCheck

        running: !Config.services.gpuType
        command: ["sh", "-c", "if command -v nvidia-smi &>/dev/null && nvidia-smi -L &>/dev/null; then echo NVIDIA; elif ls /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | grep -q .; then echo GENERIC; else echo NONE; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const detected = text.trim().toUpperCase();
                root.autoGpuType = (detected === "NVIDIA" || detected === "GENERIC") ? detected : "NONE";
            }
        }
    }

    Process {
        id: gpuUsage

        command: root.gpuType === "GENERIC" ? ["sh", "-c", "cat /sys/class/drm/card*/device/gpu_busy_percent"] : root.gpuType === "NVIDIA" ? ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"] : ["echo"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.gpuType === "GENERIC") {
                    const nextGpuPerc = ShellParse.parseGenericGpuLines(text);
                    if (nextGpuPerc === null)
                        return;
                    if (!root.nearlyEqual(root.gpuPerc, nextGpuPerc)) {
                        root.gpuPerc = nextGpuPerc;
                        root.gpuSerial++;
                    }
                } else if (root.gpuType === "NVIDIA") {
                    const parsed = ShellParse.parseNvidiaGpuLine(text);
                    if (!parsed)
                        return;
                    const nextGpuPerc = parsed.perc;
                    const nextGpuTemp = parsed.temp;
                    if (!root.nearlyEqual(root.gpuPerc, nextGpuPerc) || !root.nearlyEqual(root.gpuTemp, nextGpuTemp)) {
                        root.gpuPerc = nextGpuPerc;
                        root.gpuTemp = nextGpuTemp;
                        root.gpuSerial++;
                    }
                } else {
                    if (!root.nearlyEqual(root.gpuPerc, 0) || !root.nearlyEqual(root.gpuTemp, 0)) {
                        root.gpuPerc = 0;
                        root.gpuTemp = 0;
                        root.gpuSerial++;
                    }
                }
            }
        }
    }

    Process {
        id: sensors

        command: ["sensors"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                let cpuTemp = text.match(/(?:Package id [0-9]+|Tdie):\s+((\+|-)[0-9.]+)(°| )C/);
                if (!cpuTemp)
                    // If AMD Tdie pattern failed, try fallback on Tctl
                    cpuTemp = text.match(/Tctl:\s+((\+|-)[0-9.]+)(°| )C/);

                let changed = false;
                if (cpuTemp) {
                    const nextCpuTemp = parseFloat(cpuTemp[1]);
                    if (!root.nearlyEqual(root.cpuTemp, nextCpuTemp)) {
                        root.cpuTemp = nextCpuTemp;
                        changed = true;
                    }
                }

                if (root.gpuType !== "GENERIC") {
                    if (changed)
                        root.sensorSerial++;
                    return;
                }

                let eligible = false;
                let sum = 0;
                let count = 0;

                for (const line of text.trim().split("\n")) {
                    if (line === "Adapter: PCI adapter")
                        eligible = true;
                    else if (line === "")
                        eligible = false;
                    else if (eligible) {
                        let match = line.match(/^(temp[0-9]+|GPU core|edge)+:\s+\+([0-9]+\.[0-9]+)(°| )C/);
                        if (!match)
                            // Fall back to junction/mem if GPU doesn't have edge temp (for AMD GPUs)
                            match = line.match(/^(junction|mem)+:\s+\+([0-9]+\.[0-9]+)(°| )C/);

                        if (match) {
                            sum += parseFloat(match[2]);
                            count++;
                        }
                    }
                }

                const nextGpuTemp = count > 0 ? sum / count : 0;
                if (!root.nearlyEqual(root.gpuTemp, nextGpuTemp)) {
                    root.gpuTemp = nextGpuTemp;
                    changed = true;
                }
                if (changed)
                    root.sensorSerial++;
            }
        }
    }
}
