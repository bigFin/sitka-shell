pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "../utils/scripts/shellParse.js" as ShellParse

Singleton {
    id: root
    property int refCount: 0
    property int domainRefCount: 0
    readonly property int legacyRefCount: Math.max(0, refCount - domainRefCount)
    property int metricsRefCount: 0
    property int processRefCount: 0
    property int systemRefCount: 0
    property int gpuRefCount: 0

    readonly property bool metricsActive: legacyRefCount > 0 || metricsRefCount > 0
    readonly property bool processesActive: legacyRefCount > 0 || processRefCount > 0
    readonly property bool systemActive: legacyRefCount > 0 || systemRefCount > 0
    readonly property bool gpuActive: legacyRefCount > 0 || gpuRefCount > 0

    property int updateInterval: 2000
    property int systemUpdateInterval: 30000
    property int maxProcesses: 100
    readonly property bool isUpdating: metricsUpdating || processUpdating || systemUpdating || gpuUpdating
    property bool metricsUpdating: false
    property bool processUpdating: false
    property bool systemUpdating: false
    property bool gpuUpdating: false

    property int metricsPollCount: 0
    property int processPollCount: 0
    property int systemPollCount: 0
    property int gpuPollCount: 0
    property int metricsSerial: 0
    property int processSerial: 0
    property int systemSerial: 0
    property int gpuSerial: 0

    property var processes: []
    property string sortBy: "cpu"
    property bool sortDescending: true

    property real cpuUsage: 0
    property real totalCpuUsage: 0
    property int cpuCores: 1
    property int cpuCount: 1
    property string cpuModel: ""
    property real cpuFrequency: 0
    property real cpuTemperature: 0
    property var perCoreCpuUsage: []
    property var perCoreCpuUsagePrev: []

    property var lastCpuStats: null
    property var lastPerCoreStats: null

    property real memoryUsage: 0
    property real totalMemoryMB: 0
    property real usedMemoryMB: 0
    property real freeMemoryMB: 0
    property real availableMemoryMB: 0
    property int totalMemoryKB: 0
    property int usedMemoryKB: 0
    property int totalSwapKB: 0
    property int usedSwapKB: 0

    property real networkRxRate: 0
    property real networkTxRate: 0
    property var lastNetworkStats: null

    property real diskReadRate: 0
    property real diskWriteRate: 0
    property var lastDiskStats: null
    property var diskMounts: []

    property int historySize: 60
    property var cpuHistory: []
    property var memoryHistory: []
    property var networkHistory: ({
            "rx": [],
            "tx": []
        })
    property var diskHistory: ({
            "read": [],
            "write": []
        })

    property string kernelVersion: ""
    property string distribution: ""
    property string hostname: ""
    property string architecture: ""
    property string loadAverage: ""
    property int processCount: 0
    property int threadCount: 0
    property string bootTime: ""
    property string motherboard: ""
    property string biosVersion: ""

    // GPU Monitoring Properties

    property var gpus: [] // Array of GPU objects: {vendor, name, usage, temperature, memoryUsed, memoryTotal, card, busId}
    property var _gpuDetectCallback: null

    property string gpuDetectScript: "
for card in /sys/class/drm/card[0-9]*; do
    [ -d \"$card/device\" ] || continue
    case \"$card\" in
        *-*) continue ;;
    esac
    driver=\$(cat \"$card/device/uevent\" 2>/dev/null | grep ^DRIVER= | cut -d= -f2)
    vendor=\$(cat \"$card/device/vendor\" 2>/dev/null)
    device=\$(cat \"$card/device/device\" 2>/dev/null)
    name=\$(cat \"$card/device/uevent\" 2>/dev/null | grep ^DRIVER= | cut -d= -f2)
    busid=\$(basename \"$card\")
    pciid=\$(basename \$(readlink -f \"$card/device\") 2>/dev/null)
    if [ \"\$driver\" = \"nvidia\" ]; then
        type=\"NVIDIA\"
    elif [ \"\$(echo \"\$vendor\" | tr '[:upper:]' '[:lower:]')\" = \"0x8086\" ] || [ \"\$driver\" = \"i915\" ] || [ \"\$driver\" = \"xe\" ]; then
        type=\"INTEL\"
    elif [ -f \"$card/device/gpu_busy_percent\" ]; then
        type=\"GENERIC\"
    else
        type=\"UNKNOWN\"
    fi
    echo \"\$busid|\$type|\$vendor|\$device|\$name|\$pciid\"
done | awk -F'|' '!seen[\$6]++ {print \$0}'
"

    Process {
        id: gpuDetectProcess
        property var _callback: null
        command: ["sh", "-c", root.gpuDetectScript]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (typeof gpuDetectProcess._callback === "function") {
                    gpuDetectProcess._callback(text);
                }
            }
        }
    }

    Process {
        id: nvidiaStatsProcess
        property var _callback: null
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (typeof nvidiaStatsProcess._callback === "function") {
                    nvidiaStatsProcess._callback(text);
                }
            }
        }
    }

    // Helper: Find first matching file for a glob pattern (for hwmon)
    function findFirstMatchingFile(pattern) {
        try {
            let files = Quickshell.ls(pattern);
            if (files && files.length > 0)
                return files[0];
        } catch (e) {}
        return "";
    }

    function detectGpus(callback) {
        gpuDetectProcess._callback = function (output) {
            let lines = output.trim().split("\n");
            let detected = [];
            for (let line of lines) {
                let [card, type, vendor, device, name, pciid] = line.split("|");
                detected.push({
                    card,
                    type,
                    vendor,
                    device,
                    name,
                    pciid
                });
            }
            callback(detected);
        };
        gpuDetectProcess.running = true;
    }

    function updateGpuStats() {
        if (gpuUpdating)
            return;

        gpuUpdating = true;
        gpuPollCount++;
        detectGpus(function (gpuList) {
            let pending = gpuList.length;
            let results = [];
            if (pending === 0) {
                gpus = [];
                gpuSerial++;
                gpuUpdating = false;
                return;
            }
            for (let i = 0; i < gpuList.length; i++) {
                let gpu = gpuList[i];
                if (gpu.type === "NVIDIA") {
                    nvidiaStatsProcess._callback = function (text) {
                        let parts = text.trim().split(",");
                        if (parts.length >= 5) {
                            results.push({
                                vendor: "NVIDIA",
                                name: parts[2].trim(),
                                usage: parseFloat(parts[0]),
                                temperature: parseInt(parts[1], 10),
                                memoryUsed: parseInt(parts[3], 10),
                                memoryTotal: parseInt(parts[4], 10),
                                card: gpu.card
                            });
                        } else {
                            results.push({
                                vendor: "NVIDIA",
                                name: "NVIDIA GPU",
                                usage: null,
                                temperature: null,
                                memoryUsed: null,
                                memoryTotal: null,
                                card: gpu.card
                            });
                        }
                        pending--;
                        if (pending === 0) {
                            gpus = results;
                            gpuSerial++;
                            gpuUpdating = false;
                        }
                    };
                    nvidiaStatsProcess.command = ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu,name,memory.used,memory.total", "--format=csv,noheader,nounits", "-i", String(i)];
                    nvidiaStatsProcess.running = true;
                } else if (gpu.type === "INTEL") {
                    // i915/xe expose no unprivileged sysfs utilization counter
                    // (gpu_busy_percent is AMDGPU-only); whole-GPU load needs
                    // intel_gpu_top or perf, so usage stays null by design.
                    // Temperature reuses the standard hwmon pattern.
                    let intelTemp = null;
                    const intelHwmonGlob = "/sys/class/drm/" + gpu.card + "/device/hwmon/hwmon*/temp1_input";
                    const intelTempPath = findFirstMatchingFile(intelHwmonGlob);
                    try {
                        if (intelTempPath)
                            intelTemp = parseInt(Quickshell.readFile(intelTempPath).trim(), 10) / 1000;
                    } catch (e) {}
                    if (isNaN(intelTemp))
                        intelTemp = null;
                    results.push({
                        vendor: "Intel",
                        name: gpu.name || "Intel GPU",
                        usage: null,
                        temperature: intelTemp,
                        memoryUsed: null,
                        memoryTotal: null,
                        card: gpu.card
                    });
                    pending--;
                    if (pending === 0) {
                        gpus = results;
                        gpuSerial++;
                        gpuUpdating = false;
                    }
                } else if (gpu.type === "GENERIC") {
                    let usage = null;
                    let temp = null;
                    try {
                        usage = parseInt(Quickshell.readFile("/sys/class/drm/" + gpu.card + "/device/gpu_busy_percent").trim(), 10);
                    } catch (e) {}
                    if (isNaN(usage))
                        usage = null;
                    let hwmonGlob = "/sys/class/drm/" + gpu.card + "/device/hwmon/hwmon*/temp1_input";
                    let tempPath = findFirstMatchingFile(hwmonGlob);
                    try {
                        if (tempPath)
                            temp = parseInt(Quickshell.readFile(tempPath).trim(), 10) / 1000;
                    } catch (e) {}
                    if (isNaN(temp))
                        temp = null;
                    results.push({
                        vendor: "GENERIC",
                        name: gpu.name || "Generic GPU",
                        usage: usage,
                        temperature: temp,
                        memoryUsed: null,
                        memoryTotal: null,
                        card: gpu.card
                    });
                    pending--;
                    if (pending === 0) {
                        gpus = results;
                        gpuSerial++;
                        gpuUpdating = false;
                    }
                } else {
                    results.push({
                        vendor: "UNKNOWN",
                        name: gpu.name || "Unknown GPU",
                        usage: null,
                        temperature: null,
                        memoryUsed: null,
                        memoryTotal: null,
                        card: gpu.card
                    });
                    pending--;
                    if (pending === 0) {
                        gpus = results;
                        gpuSerial++;
                        gpuUpdating = false;
                    }
                }
            }
        });
    }

    // END GPU STUFF

    function addRef(domains: var): void {
        const refs = normaliseDomains(domains);
        refCount++;
        domainRefCount++;
        adjustDomainRefs(refs, 1);
        updateDomains(refs);
    }

    function removeRef(domains: var): void {
        const refs = normaliseDomains(domains);
        refCount = Math.max(0, refCount - 1);
        domainRefCount = Math.max(0, domainRefCount - 1);
        adjustDomainRefs(refs, -1);
    }

    function normaliseDomains(domains: var): var {
        if (!domains)
            return ["metrics", "processes", "system", "gpu"];
        if (typeof domains === "string")
            return [domains];
        return domains;
    }

    function adjustDomainRefs(domains: var, delta: int): void {
        for (let i = 0; i < domains.length; i++) {
            switch (domains[i]) {
            case "metrics":
                metricsRefCount = Math.max(0, metricsRefCount + delta);
                break;
            case "processes":
                processRefCount = Math.max(0, processRefCount + delta);
                break;
            case "system":
                systemRefCount = Math.max(0, systemRefCount + delta);
                break;
            case "gpu":
                gpuRefCount = Math.max(0, gpuRefCount + delta);
                break;
            }
        }
    }

    function updateDomains(domains: var): void {
        for (let i = 0; i < domains.length; i++) {
            switch (domains[i]) {
            case "metrics":
                updateMetricsStats();
                break;
            case "processes":
                updateProcessStats();
                break;
            case "system":
                updateSystemStats();
                break;
            case "gpu":
                updateGpuStats();
                break;
            }
        }
    }

    function updateAllStats() {
        if (metricsActive)
            updateMetricsStats();
        if (processesActive)
            updateProcessStats();
        if (systemActive)
            updateSystemStats();
        if (gpuActive)
            updateGpuStats();
    }

    function updateMetricsStats(): void {
        if (!metricsActive || metricsUpdating || IdleService.isIdle)
            return;
        metricsUpdating = true;
        metricsPollCount++;
        metricsStatsProcess.running = true;
    }

    function updateProcessStats(): void {
        if (!processesActive || processUpdating || IdleService.isIdle)
            return;
        processUpdating = true;
        processPollCount++;
        processStatsProcess.running = true;
    }

    function updateSystemStats(): void {
        if (!systemActive || systemUpdating || IdleService.isIdle)
            return;
        systemUpdating = true;
        systemPollCount++;
        systemStatsProcess.running = true;
    }

    function setSortBy(newSortBy) {
        if (newSortBy !== sortBy) {
            sortBy = newSortBy;
            sortProcessesInPlace();
            if (processesActive)
                updateProcessStats();
        }
    }

    function toggleSortOrder() {
        sortDescending = !sortDescending;
        sortProcessesInPlace();
        if (processesActive)
            updateProcessStats();
    }

    function sortProcessesInPlace() {
        if (processes.length === 0)
            return;

        const sortedProcesses = [...processes];

        sortedProcesses.sort((a, b) => {
            let aVal, bVal;

            switch (sortBy) {
            case "cpu":
                aVal = parseFloat(a.cpu) || 0;
                bVal = parseFloat(b.cpu) || 0;
                break;
            case "memory":
                aVal = parseFloat(a.memoryPercent) || 0;
                bVal = parseFloat(b.memoryPercent) || 0;
                break;
            case "name":
                aVal = a.command || "";
                bVal = b.command || "";
                break;
            case "pid":
                aVal = parseInt(a.pid) || 0;
                bVal = parseInt(b.pid) || 0;
                break;
            default:
                aVal = parseFloat(a.cpu) || 0;
                bVal = parseFloat(b.cpu) || 0;
            }

            if (typeof aVal === "string") {
                return sortDescending ? bVal.localeCompare(aVal) : aVal.localeCompare(bVal);
            } else {
                return sortDescending ? bVal - aVal : aVal - bVal;
            }
        });

        processes = sortedProcesses;
    }

    function killProcess(pid) {
        if (pid > 0) {
            Quickshell.execDetached("kill", [pid.toString()]);
        }
    }

    function addToHistory(array, value) {
        array.push(value);
        if (array.length > historySize)
            array.shift();
    }

    function calculateCpuUsage(currentStats, lastStats) {
        return ShellParse.calculateCpuUsage(currentStats, lastStats);
    }

    function parseUnifiedStats(text, source: string): bool {
        function num(x) {
            return (typeof x === "number" && !isNaN(x)) ? x : 0;
        }

        let data;
        try {
            data = JSON.parse(text);
        } catch (error) {
            console.error("SysMonitorService: Failed to parse JSON:", error, "Raw text:", text.slice(0, 300));
            return false;
        }

        if (data.memory) {
            const m = data.memory;
            totalMemoryKB = num(m.total);
            const free = num(m.free);
            const buf = num(m.buffers);
            const cached = num(m.cached);
            const shared = num(m.shared);
            usedMemoryKB = totalMemoryKB - free - buf - cached;
            totalSwapKB = num(m.swaptotal);
            usedSwapKB = num(m.swaptotal) - num(m.swapfree);
            totalMemoryMB = totalMemoryKB / 1024;
            usedMemoryMB = usedMemoryKB / 1024;
            freeMemoryMB = (totalMemoryKB - usedMemoryKB) / 1024;
            availableMemoryMB = num(m.available) ? num(m.available) / 1024 : (free + buf + cached) / 1024;
            memoryUsage = totalMemoryKB > 0 ? (usedMemoryKB / totalMemoryKB) * 100 : 0;
        }

        if (data.cpu) {
            cpuCores = data.cpu.count || 1;
            cpuCount = data.cpu.count || 1;
            cpuModel = data.cpu.model || "";
            cpuFrequency = data.cpu.frequency || 0;
            cpuTemperature = data.cpu.temperature || 0;

            if (data.cpu.total && data.cpu.total.length >= 8) {
                const currentStats = data.cpu.total;
                const usage = calculateCpuUsage(currentStats, lastCpuStats);
                cpuUsage = usage;
                totalCpuUsage = usage;
                lastCpuStats = [...currentStats];
            }

            if (data.cpu.cores) {
                const coreUsages = [];
                for (let i = 0; i < data.cpu.cores.length; i++) {
                    const currentCoreStats = data.cpu.cores[i];
                    if (currentCoreStats && currentCoreStats.length >= 8) {
                        let lastCoreStats = null;
                        if (lastPerCoreStats && lastPerCoreStats[i]) {
                            lastCoreStats = lastPerCoreStats[i];
                        }

                        const usage = calculateCpuUsage(currentCoreStats, lastCoreStats);
                        coreUsages.push(usage);
                    }
                }

                if (JSON.stringify(perCoreCpuUsage) !== JSON.stringify(coreUsages)) {
                    // Store previous values before updating current ones
                    perCoreCpuUsagePrev = [...perCoreCpuUsage];
                    perCoreCpuUsage = coreUsages;
                }

                lastPerCoreStats = data.cpu.cores.map(core => [...core]);
            }
        }

        if (data.network) {
            let totalRx = 0;
            let totalTx = 0;
            for (const iface of data.network) {
                totalRx += iface.rx;
                totalTx += iface.tx;
            }
            if (lastNetworkStats) {
                const timeDiff = updateInterval / 1000;
                const rxDiff = totalRx - lastNetworkStats.rx;
                const txDiff = totalTx - lastNetworkStats.tx;
                networkRxRate = Math.max(0, rxDiff / timeDiff);
                networkTxRate = Math.max(0, txDiff / timeDiff);
                addToHistory(networkHistory.rx, networkRxRate / 1024);
                addToHistory(networkHistory.tx, networkTxRate / 1024);
            }
            lastNetworkStats = {
                "rx": totalRx,
                "tx": totalTx
            };
        }

        if (data.disk) {
            let totalRead = 0;
            let totalWrite = 0;
            for (const disk of data.disk) {
                totalRead += disk.read * 512;
                totalWrite += disk.write * 512;
            }
            if (lastDiskStats) {
                const timeDiff = updateInterval / 1000;
                const readDiff = totalRead - lastDiskStats.read;
                const writeDiff = totalWrite - lastDiskStats.write;
                diskReadRate = Math.max(0, readDiff / timeDiff);
                diskWriteRate = Math.max(0, writeDiff / timeDiff);
                addToHistory(diskHistory.read, diskReadRate / (1024 * 1024));
                addToHistory(diskHistory.write, diskWriteRate / (1024 * 1024));
            }
            lastDiskStats = {
                "read": totalRead,
                "write": totalWrite
            };
        }

        if (data.processes) {
            processes = ShellParse.buildProcessRows(data.processes);
            sortProcessesInPlace();
        }

        if (data.system) {
            kernelVersion = data.system.kernel || "";
            distribution = data.system.distro || "";
            hostname = data.system.hostname || "";
            architecture = data.system.arch || "";
            loadAverage = data.system.loadavg || "";
            processCount = data.system.processes || 0;
            threadCount = data.system.threads || 0;
            bootTime = data.system.boottime || "";
            motherboard = data.system.motherboard || "";
            biosVersion = data.system.bios || "";
        }

        if (data.diskmounts) {
            diskMounts = data.diskmounts;
        }

        if (source === "metrics") {
            addToHistory(cpuHistory, cpuUsage);
            addToHistory(memoryHistory, memoryUsage);
        }

        switch (source) {
        case "metrics":
            metricsSerial++;
            break;
        case "processes":
            processSerial++;
            break;
        case "system":
            systemSerial++;
            break;
        }

        return true;
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

    Timer {
        id: metricsUpdateTimer
        interval: root.updateInterval
        running: root.metricsActive && !IdleService.isIdle
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateMetricsStats()
    }

    Timer {
        id: processUpdateTimer
        interval: root.updateInterval
        running: root.processesActive && !IdleService.isIdle
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateProcessStats()
    }

    Timer {
        id: gpuUpdateTimer
        interval: root.updateInterval
        running: root.gpuActive && !IdleService.isIdle
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateGpuStats()
    }

    Timer {
        id: systemUpdateTimer
        interval: root.systemUpdateInterval
        running: root.systemActive && !IdleService.isIdle
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateSystemStats()
    }

    Connections {
        target: IdleService
        function onIdleChanged(idle) {
            if (!idle)
                root.updateAllStats();
        }
    }

    readonly property string scriptBody: `set -Eeuo pipefail
trap 'echo "ERR at line $LINENO: $BASH_COMMAND (exit $?)" >&2' ERR

mode=\${1:-metrics}
sort_key=\${2:-cpu}
max_procs=\${3:-20}

json_escape() { sed -e 's/\\\\/\\\\\\\\/g' -e 's/"/\\\\"/g' -e ':a;N;$!ba;s/\\n/\\\\n/g'; }
emit_comma() {
    if [ -n "\${emitted:-}" ]; then
        printf ","
    fi
    emitted=1
}
want() {
    [ "$mode" = "all" ] || [ "$mode" = "$1" ]
}

printf "{"

if want metrics; then
    emit_comma
    mem_line="$(awk '/^MemTotal:/{t=$2}
                 /^MemFree:/{f=$2}
                 /^MemAvailable:/{a=$2}
                 /^Buffers:/{b=$2}
                 /^Cached:/{c=$2}
                 /^Shmem:/{s=$2}
                 /^SwapTotal:/{st=$2}
                 /^SwapFree:/{sf=$2}
                 END{printf "%d %d %d %d %d %d %d %d",t,f,a,b,c,s,st,sf}' /proc/meminfo)"
    read -r MT MF MA BU CA SH ST SF <<< "$mem_line"
    printf '"memory":{"total":%d,"free":%d,"available":%d,"buffers":%d,"cached":%d,"shared":%d,"swaptotal":%d,"swapfree":%d}' \\
       "$MT" "$MF" "$MA" "$BU" "$CA" "$SH" "$ST" "$SF"

    emit_comma
    cpu_count=$(nproc)
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//' | json_escape || echo 'Unknown')
    cpu_freq=$(awk -F: '/cpu MHz/{gsub(/ /,"",$2);print $2;exit}' /proc/cpuinfo || echo 0)
    cpu_temp=$(if [ -r /sys/class/thermal/thermal_zone0/temp ]; then
             awk '{printf "%.1f",$1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0
           else echo 0; fi)

    printf '"cpu":{"count":%d,"model":"%s","frequency":%s,"temperature":%s,' \\
       "$cpu_count" "$cpu_model" "$cpu_freq" "$cpu_temp"

    printf '"total":'
    awk 'NR==1 {printf "[%d,%d,%d,%d,%d,%d,%d,%d]", $2,$3,$4,$5,$6,$7,$8,$9; exit}' /proc/stat

    printf ',"cores":['
    cpu_cores=$(nproc)
    awk -v n="$cpu_cores" 'BEGIN{c=0}
     /^cpu[0-9]+/ {
       if(c>0) printf ",";
       printf "[%d,%d,%d,%d,%d,%d,%d,%d]", $2,$3,$4,$5,$6,$7,$8,$9;
       c++;
       if(c==n) exit
     }' /proc/stat
    printf ']}'

    emit_comma
    printf '"network":['
    tmp_net=$(mktemp)
    grep -E '(wlan|eth|enp|wlp|ens|eno)' /proc/net/dev > "$tmp_net" || true
    nfirst=1
    while IFS= read -r line; do
    [ -z "$line" ] && continue
    iface=$(echo "$line" | awk '{print $1}' | sed 's/://')
    rx_bytes=$(echo "$line" | awk '{print $2}')
    tx_bytes=$(echo "$line" | awk '{print $10}')
    [ $nfirst -eq 1 ] || printf ","
    printf '{"name":"%s","rx":%d,"tx":%d}' "$iface" "$rx_bytes" "$tx_bytes"
    nfirst=0
    done < "$tmp_net"
    rm -f "$tmp_net"
    printf ']'

    emit_comma
    printf '"disk":['
    tmp_disk=$(mktemp)
    grep -E ' (sd[a-z]+|nvme[0-9]+n[0-9]+|vd[a-z]+|dm-[0-9]+|mmcblk[0-9]+) ' /proc/diskstats > "$tmp_disk" || true
    dfirst=1
    while IFS= read -r line; do
    [ -z "$line" ] && continue
    name=$(echo "$line" | awk '{print $3}')
    read_sectors=$(echo "$line" | awk '{print $6}')
    write_sectors=$(echo "$line" | awk '{print $10}')
    [ $dfirst -eq 1 ] || printf ","
    printf '{"name":"%s","read":%d,"write":%d}' "$name" "$read_sectors" "$write_sectors"
    dfirst=0
    done < "$tmp_disk"
    rm -f "$tmp_disk"
    printf ']'
fi

if want processes; then
    emit_comma
    printf '"processes":['
    case "$sort_key" in
    cpu)    SORT_OPT="--sort=-pcpu" ;;
    memory) SORT_OPT="--sort=-pmem" ;;
    name)   SORT_OPT="--sort=+comm" ;;
    pid)    SORT_OPT="--sort=+pid" ;;
    *)      SORT_OPT="--sort=-pcpu" ;;
    esac

    ps -eo pid,ppid,pcpu,pmem,rss,comm,cmd --no-headers \$SORT_OPT | head -n \"\$max_procs\" | awk '
BEGIN { first = 1 }
{
    pid=\$1; ppid=\$2; cpu=\$3; memp=\$4; memk=\$5; comm=\$6
    rest = \$0; sub(/^[[:space:]]*([^[:space:]]+[[:space:]]+){6}/, \"\", rest)
    gsub(/\\\\/, \"\\\\\\\\\", rest); gsub(/\"/, \"\\\\\\\"\", rest)
    if (!first) printf \",\"
    first = 0
    printf \"{\\\"pid\\\":%s,\\\"ppid\\\":%s,\\\"cpu\\\":%s,\\\"memoryPercent\\\":%s,\\\"memoryKB\\\":%s,\\\"command\\\":\\\"%s\\\",\\\"fullCommand\\\":\\\"%s\\\"}\", pid, ppid, cpu, memp, memk, comm, rest
}' || true
    printf ']'
fi

if want system; then
    dmip="/sys/class/dmi/id"
    [ -d "$dmip" ] || dmip="/sys/devices/virtual/dmi/id"
    mb_vendor=$([ -r "$dmip/board_vendor" ] && cat "$dmip/board_vendor" | json_escape || echo "Unknown")
    mb_name=$([ -r "$dmip/board_name" ] && cat "$dmip/board_name" | json_escape || echo "")
    bios_ver=$([ -r "$dmip/bios_version" ] && cat "$dmip/bios_version" | json_escape || echo "Unknown")
    bios_date=$([ -r "$dmip/bios_date" ] && cat "$dmip/bios_date" | json_escape || echo "")

    kern_ver=$(uname -r | json_escape)
    distro=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"' | json_escape || echo 'Unknown')
    host_name=$(hostname | json_escape)
    arch_name=$(uname -m)
    load_avg=$(cut -d' ' -f1-3 /proc/loadavg)
    proc_count=$(( $(ps aux | wc -l) - 1 ))
    thread_count=$(ps -eL | wc -l)
    boot_time=$(who -b 2>/dev/null | awk '{print $3, $4}' | json_escape || echo 'Unknown')

    emit_comma
    printf '"system":{"kernel":"%s","distro":"%s","hostname":"%s","arch":"%s","loadavg":"%s","processes":%d,"threads":%d,"boottime":"%s","motherboard":"%s %s","bios":"%s %s"}' \\
    "$kern_ver" "$distro" "$host_name" "$arch_name" "$load_avg" "$proc_count" "$thread_count" "$boot_time" "$mb_vendor" "$mb_name" "$bios_ver" "$bios_date"

    emit_comma
    printf '"diskmounts":['
    tmp_mounts=$(mktemp)
    df -h --output=source,target,fstype,size,used,avail,pcent | tail -n +2 | grep -vE '^(tmpfs|devtmpfs)' | head -n 10 > "$tmp_mounts" || true
    mfirst=1
    while IFS= read -r line; do
    [ -z "$line" ] && continue
    device=$(echo "$line" | awk '{print $1}' | json_escape)
    mount=$(echo "$line" | awk '{print $2}' | json_escape)
    fstype=$(echo "$line" | awk '{print $3}')
    size=$(echo "$line" | awk '{print $4}')
    used=$(echo "$line" | awk '{print $5}')
    avail=$(echo "$line" | awk '{print $6}')
    percent=$(echo "$line" | awk '{print $7}')
    [ $mfirst -eq 1 ] || printf ","
    printf '{"device":"%s","mount":"%s","fstype":"%s","size":"%s","used":"%s","avail":"%s","percent":"%s"}' \\
           "$device" "$mount" "$fstype" "$size" "$used" "$avail" "$percent"
    mfirst=0
    done < "$tmp_mounts"
    rm -f "$tmp_mounts"
    printf ']'
fi

printf "}\\n"`

    function statsCommand(mode: string): var {
        return ["bash", "-c", "bash -s \"$1\" \"$2\" \"$3\" <<'QS_EOF'\\n" + root.scriptBody + "\\nQS_EOF\\n", "qsmon", mode, root.sortBy, root.maxProcesses];
    }

    function parseStatsOutput(output: string, source: string): bool {
        if (!output.trim())
            return false;

        const fullText = output.trim();
        const lastBraceIndex = fullText.lastIndexOf('}');
        if (lastBraceIndex === -1) {
            console.error("SysMonitorService: No JSON object found in output.", fullText);
            return false;
        }
        const jsonText = fullText.substring(0, lastBraceIndex + 1);
        return root.parseUnifiedStats(jsonText, source);
    }

    Process {
        id: metricsStatsProcess
        command: root.statsCommand("metrics")
        running: false
        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("Metrics stats process failed with exit code:", exitCode);
            root.metricsUpdating = false;
        }
        stdout: StdioCollector {
            onStreamFinished: root.parseStatsOutput(text, "metrics")
        }
    }

    Process {
        id: processStatsProcess
        command: root.statsCommand("processes")
        running: false
        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("Process stats process failed with exit code:", exitCode);
            root.processUpdating = false;
        }
        stdout: StdioCollector {
            onStreamFinished: root.parseStatsOutput(text, "processes")
        }
    }

    Process {
        id: systemStatsProcess
        command: root.statsCommand("system")
        running: false
        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("System stats process failed with exit code:", exitCode);
            root.systemUpdating = false;
        }
        stdout: StdioCollector {
            onStreamFinished: root.parseStatsOutput(text, "system")
        }
    }

    function debug() {
        SysMonitorService.addRef();
        SysMonitorService.updateAllStats();
    }


}
