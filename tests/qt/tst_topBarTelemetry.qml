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
