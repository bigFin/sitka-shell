pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real cpuPerc
    property real cpuTemp
    readonly property string gpuType: Config.services.gpuType.toUpperCase() || autoGpuType
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
        const mib = 1024;
        const gib = 1024 ** 2;
        const tib = 1024 ** 3;

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
        return Math.abs((a || 0) - (b || 0)) < 0.0001;
    }

    function pollCpu(): void {
        cpuPollCount++;
        stat.reload();
    }

    function pollMemory(): void {
        memoryPollCount++;
        meminfo.reload();
    }

    function pollStorage(): void {
        if (storage.running)
            return;
        storagePollCount++;
        storage.running = true;
    }

    function pollGpu(): void {
        if (gpuUsage.running)
            return;
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
        running: root.cpuActive
        interval: 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollCpu()
    }

    Timer {
        running: root.memoryActive
        interval: 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollMemory()
    }

    Timer {
        running: root.storageActive
        interval: 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollStorage()
    }

    Timer {
        running: root.gpuActive
        interval: 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollGpu()
    }

    Timer {
        running: root.sensorActive
        interval: 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pollSensors()
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: {
            const data = text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
            if (data) {
                const stats = data.slice(1).map(n => parseInt(n, 10));
                const total = stats.reduce((a, b) => a + b, 0);
                const idle = stats[3] + (stats[4] ?? 0);

                const totalDiff = total - root.lastCpuTotal;
                const idleDiff = idle - root.lastCpuIdle;
                const nextCpuPerc = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0;
                if (!root.nearlyEqual(root.cpuPerc, nextCpuPerc)) {
                    root.cpuPerc = nextCpuPerc;
                    root.cpuSerial++;
                }

                root.lastCpuTotal = total;
                root.lastCpuIdle = idle;
            }
        }
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: {
            const data = text();
            const nextMemTotal = parseInt(data.match(/MemTotal: *(\d+)/)[1], 10) || 1;
            const nextMemUsed = (nextMemTotal - parseInt(data.match(/MemAvailable: *(\d+)/)[1], 10)) || 0;
            if (!root.nearlyEqual(root.memTotal, nextMemTotal) || !root.nearlyEqual(root.memUsed, nextMemUsed)) {
                root.memTotal = nextMemTotal;
                root.memUsed = nextMemUsed;
                root.memorySerial++;
            }
        }
    }

    Process {
        id: storage

        command: ["sh", "-c", "df | grep '^/dev/' | awk '{print $1, $3, $4}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const deviceMap = new Map();

                for (const line of text.trim().split("\n")) {
                    if (line.trim() === "")
                        continue;

                    const parts = line.trim().split(/\s+/);
                    if (parts.length >= 3) {
                        const device = parts[0];
                        const used = parseInt(parts[1], 10) || 0;
                        const avail = parseInt(parts[2], 10) || 0;

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
                if (!root.nearlyEqual(root.storageUsed, totalUsed) || !root.nearlyEqual(root.storageTotal, nextStorageTotal)) {
                    root.storageUsed = totalUsed;
                    root.storageTotal = nextStorageTotal;
                    root.storageSerial++;
                }
            }
        }
    }

    Process {
        id: gpuTypeCheck

        running: !Config.services.gpuType
        command: ["sh", "-c", "if command -v nvidia-smi &>/dev/null && nvidia-smi -L &>/dev/null; then echo NVIDIA; elif ls /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | grep -q .; then echo GENERIC; else echo NONE; fi"]
        stdout: StdioCollector {
            onStreamFinished: root.autoGpuType = text.trim()
        }
    }

    Process {
        id: gpuUsage

        command: root.gpuType === "GENERIC" ? ["sh", "-c", "cat /sys/class/drm/card*/device/gpu_busy_percent"] : root.gpuType === "NVIDIA" ? ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"] : ["echo"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.gpuType === "GENERIC") {
                    const percs = text.trim().split("\n").filter(d => d !== "");
                    const sum = percs.reduce((acc, d) => acc + parseInt(d, 10), 0);
                    const nextGpuPerc = percs.length > 0 ? sum / percs.length / 100 : 0;
                    if (!root.nearlyEqual(root.gpuPerc, nextGpuPerc)) {
                        root.gpuPerc = nextGpuPerc;
                        root.gpuSerial++;
                    }
                } else if (root.gpuType === "NVIDIA") {
                    const [usage, temp] = text.trim().split(",");
                    const nextGpuPerc = parseInt(usage, 10) / 100;
                    const nextGpuTemp = parseInt(temp, 10);
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
