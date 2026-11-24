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
    function test_battery() {
        const first = createTemporaryObject(bar, testCase);
        compare(Config.bar.telemetry.showBattery, false);
        compare(findChild(first, "batteryReading"), null);
        compare(Probe.deviceStarts, 0);
        Config.bar.telemetry.showBattery = true;
        const reading = findChild(first, "batteryReading");
        verify(reading);
        const dev = UPower.displayDevice;
        verify(!reading.visible);
        dev.ready = true;
        dev.isPresent = true;
        verify(!reading.visible); // Desktop or peripheral, not a system battery.
        dev.isLaptopBattery = true;
        verify(label(first, "BAT —")); // Unknown state and default numeric fields.
        dev.state = UPowerDeviceState.Empty;
        verify(label(first, "BAT 0% empty"));
        dev.state = UPowerDeviceState.Charging;
        verify(label(first, "BAT — charge")); // Optional Percentage also defaults to 0 in Quickshell.
        dev.percentage = 0.73;
        dev.changeRate = 11.7;
        dev.state = UPowerDeviceState.Charging;
        verify(label(first, "BAT 73% +11.7W"));
        dev.state = UPowerDeviceState.Discharging;
        verify(label(first, "BAT 73% −11.7W"));
        dev.changeRate = 0; // UPower cannot distinguish an unsupported rate from zero.
        verify(label(first, "BAT 73% drain"));
        dev.percentage = NaN;
        verify(label(first, "BAT — drain"));
        dev.percentage = 1;
        dev.state = UPowerDeviceState.FullyCharged;
        verify(label(first, "BAT 100% full"));
        const other = createTemporaryObject(bar, testCase);
        verify(label(other, "BAT 100% full"));
        compare(Probe.deviceStarts, 1);
        counts(0, 0); // Neither screen leases polled CPU or RAM domains.
        first.width = 238;
        tryVerify(() => !findChild(first, "batteryReading"));
        verify(label(first, "12:00"));
        compare(first.children.find(child => child.count === 3).width, 90);
        first.width = 900;
        verify(label(first, "BAT 100% full"));
        other.visible = false;
        tryVerify(() => !findChild(other, "batteryReading"));
        dev.isPresent = false;
        verify(!label(first, "BAT 100% full"));
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
