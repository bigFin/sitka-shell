import QtQuick
import QtTest
import "."

TestCase {
    id: testCase
    name: "TopBarTelemetry"
    when: windowShown
    visible: true
    width: 1000
    height: 100

    Component {
        id: bar
        TopBar { width: 900; height: 32; screen: ({name:"fixture"}); visibilities: ({launcher:false}) }
    }
    function label(item, text) {
        if (item.visible && item.text === text) return item;
        for (const child of item.children) {
            const found = label(child, text);
            if (found) return found;
        }
        return null;
    }
    function counts(cpu, memory) {
        tryCompare(SystemUsage, "cpuRefs", cpu);
        tryCompare(SystemUsage, "memoryRefs", memory);
    }
    function test_codexWeekly() {
        const first = createTemporaryObject(bar, testCase);
        compare(Config.bar.telemetry.showCodexWeekly, false);
        compare(AgentUsage.codexRefs, 0);
        Config.bar.telemetry.showCodexWeekly = true;
        const meter = label(first, "Codex —");
        verify(meter);
        const dial = meter.children.find(child => child.usedPercent !== undefined);
        verify(dial);
        compare(dial.usedPercent, -1);
        compare(meter.Accessible.name, "Codex weekly usage unavailable");
        tryCompare(AgentUsage, "codexRefs", 1);
        AgentUsage.codexWeeklyQuota = ({usedPercent: 0, resetsAt: null});
        verify(label(first, "Codex 0% used"));
        compare(dial.usedPercent, 0);
        AgentUsage.codexWeeklyQuota = ({usedPercent: 43.25, resetsAt: null});
        verify(label(first, "Codex 43.25% used"));
        compare(dial.usedPercent, 43.25);
        compare(meter.Accessible.name, "Codex weekly: 43.25% used");
        AgentUsage.codexWeeklyQuota = ({usedPercent: 89.9});
        compare(dial.sweepInk, dial.ink);
        AgentUsage.codexWeeklyQuota = ({usedPercent: 90});
        compare(dial.sweepInk, Qt.color(Colours.palette.m3error));
        AgentUsage.codexError = "request failed";
        verify(label(first, "Codex —"));
        compare(dial.usedPercent, -1);
        Config.bar.telemetry.showCodexWeekly = false;
        tryCompare(AgentUsage, "codexRefs", 0);
        verify(!label(first, "Codex —"));
        AgentUsage.codexError = "";
        AgentUsage.codexWeeklyQuota = null;
    }
    function test_weeklyFit() {
        Config.bar.telemetry.showCpu = Config.bar.telemetry.showMemory = Config.bar.telemetry.showBattery = true;
        const first = createTemporaryObject(bar, testCase);
        const dev = UPower.displayDevice;
        dev.ready = dev.isPresent = dev.isLaptopBattery = true;
        dev.state = UPowerDeviceState.Discharging;
        dev.percentage = 0.73;
        dev.changeRate = 11.7;
        const strip = first.children.find(child => child.count === 3);
        const reset = new Date(2030, 0, 2, 9, 15);
        AgentUsage.codexWeeklyQuota = ({usedPercent: 100, resetsAt: reset.getTime()});
        const compact = "Codex 100% used";
        const detail = compact + " · resets " + Qt.formatDateTime(reset, "ddd HH:mm");
        Config.bar.telemetry.showCodexWeekly = true;
        first.width = 1250;
        tryVerify(() => !!label(first, detail));
        let sawCompact = false, sawBatteryOnly = false;
        for (let w = 1000; w >= 450; w -= 20) {
            first.width = w;
            first.children.find(child => child.forceLayout && child.spacing === 12).forceLayout();
            compare(strip.width, 90);
            const bat = label(first, "73% −11.7W");
            const weekly = label(first, compact) || label(first, detail);
            if (weekly) {
                verify(bat);
                verify(strip.x + strip.width + 8 <= bat.mapToItem(first, 0, 0).x);
                const batteryEnd = bat.mapToItem(first, bat.width, 0).x;
                const quotaStart = weekly.mapToItem(first, 0, 0).x;
                verify(batteryEnd < quotaStart, `width ${w}: battery ends ${batteryEnd}, quota starts ${quotaStart}`);
                if (weekly.text === compact) sawCompact = true;
            } else if (bat) {
                sawBatteryOnly = true;
                counts(1, 1);
                compare(AgentUsage.codexRefs, 0);
            }
        }
        verify(sawCompact && sawBatteryOnly, "drop reset, then weekly, before existing telemetry");
        first.width = 1250;
        tryCompare(AgentUsage, "codexRefs", 1);
        first.visible = false;
        tryCompare(AgentUsage, "codexRefs", 0);
        Config.bar.telemetry.showCpu = Config.bar.telemetry.showMemory = Config.bar.telemetry.showBattery = false;
        Config.bar.telemetry.showCodexWeekly = false;
        AgentUsage.codexWeeklyQuota = null;
    }
    function test_battery() {
        const first = createTemporaryObject(bar, testCase);
        compare(Config.bar.telemetry.showBattery, false);
        compare(findChild(first, "batteryReading"), null);
        compare(Probe.deviceStarts, 0);
        Config.bar.telemetry.showBattery = true;
        const reading = findChild(first, "batteryReading");
        verify(reading);
        const gauge = reading.children.find(child => child.charging !== undefined);
        verify(gauge);
        const dev = UPower.displayDevice;
        verify(!reading.visible);
        dev.ready = true;
        dev.isPresent = true;
        verify(!reading.visible); // Desktop or peripheral, not a system battery.
        dev.isLaptopBattery = true;
        verify(label(first, "—")); // Unknown state and default numeric fields.
        dev.state = UPowerDeviceState.Empty;
        verify(label(first, "0% empty"));
        compare(gauge.level, 0);
        dev.state = UPowerDeviceState.Charging;
        verify(label(first, "— charge")); // Optional Percentage also defaults to 0 in Quickshell.
        compare(gauge.level, -1);
        compare(gauge.charging, true);
        dev.percentage = 0.73;
        dev.changeRate = 11.7;
        dev.state = UPowerDeviceState.Charging;
        verify(label(first, "73% +11.7W"));
        dev.state = UPowerDeviceState.Discharging;
        verify(label(first, "73% −11.7W"));
        compare(gauge.level, 0.73);
        compare(gauge.charging, false);
        compare(reading.Accessible.name, "Battery: 73% drain, 73% −11.7W");
        dev.percentage = 0.201;
        compare(gauge.fillInk, gauge.ink);
        dev.percentage = 0.20;
        compare(gauge.fillInk, Qt.color(Colours.palette.m3error));
        for (const state of [UPowerDeviceState.Charging, UPowerDeviceState.PendingDischarge, UPowerDeviceState.Unknown]) {
            dev.state = state;
            compare(gauge.fillInk, gauge.ink);
        }
        dev.state = UPowerDeviceState.Discharging;
        dev.percentage = 0.73;
        dev.changeRate = 0; // UPower cannot distinguish an unsupported rate from zero.
        verify(label(first, "73% drain"));
        dev.percentage = NaN;
        verify(label(first, "— drain"));
        dev.percentage = 1;
        dev.state = UPowerDeviceState.FullyCharged;
        verify(label(first, "100% full"));
        const other = createTemporaryObject(bar, testCase);
        verify(label(other, "100% full"));
        compare(Probe.deviceStarts, 1);
        counts(0, 0); // Neither screen leases polled CPU or RAM domains.
        first.width = 238;
        tryVerify(() => !findChild(first, "batteryReading"));
        verify(label(first, "12:00"));
        compare(first.children.find(child => child.count === 3).width, 90);
        first.width = 900;
        verify(label(first, "100% full"));
        other.visible = false;
        tryVerify(() => !findChild(other, "batteryReading"));
        dev.isPresent = false;
        verify(!label(first, "100% full"));
        // Absence shouldn't change CPU placement or the clock/workspace fit.
        Config.bar.telemetry.showCpu = true;
        first.width = 410;
        counts(1, 0);
        verify(label(first, "CPU —"));
        compare(first.children.find(child => child.count === 3).width, 90);
        dev.isPresent = true;
        counts(1, 0);
        tryVerify(() => !findChild(first, "batteryReading"));
        Config.bar.telemetry.showCpu = false;
        Config.bar.telemetry.showBattery = false;
        tryVerify(() => !findChild(first, "batteryReading"));
    }
    function test_lifecycle() {
        const first = createTemporaryObject(bar, testCase);
        verify(first);
        verify(Config.bar.telemetry !== undefined, "independent top-bar telemetry switches");
        compare(Config.bar.telemetry.showCpu, false);
        compare(Config.bar.telemetry.showMemory, false);
        counts(0, 0);
        Config.bar.telemetry.showCpu = true;
        counts(1, 0);
        verify(label(first, "CPU —"));
        SystemUsage.cpuState = ({available:true, stale:false});
        verify(label(first, "CPU 0%"));
        Config.bar.telemetry.showMemory = true;
        counts(1, 1);
        verify(label(first, "RAM 75% stale"));
        const other = createTemporaryObject(bar, testCase);
        counts(2, 2);
        other.visible = false;
        counts(1, 1);
        first.width = 238; // Three workspace buttons still fit beside the short clock.
        counts(0, 0);
        verify(!label(first, "CPU 0%") && !label(first, "RAM 75% stale"));
        verify(label(first, "12:00"));
        const strip = first.children.find(child => child.count === 3);
        verify(strip);
        tryCompare(strip, "width", 90);
        first.width = 900;
        counts(1, 1);
        Config.bar.telemetry.showCpu = false;
        counts(0, 1);
        verify(!label(first, "CPU 0%") && label(first, "RAM 75% stale"));
        other.visible = true;
        counts(0, 2);
        first.destroy();
        counts(0, 1);
        other.destroy();
        counts(0, 0);
    }
}
