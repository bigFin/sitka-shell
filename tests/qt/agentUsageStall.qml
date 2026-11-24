import QtQuick
import Quickshell
import qs.services
import "bar" as Fixture

ShellRoot {
    id: root
    property int phase: 0
    property double issuedAt: 0
    function instrument(item) {
        if (item.visible && item.text?.startsWith("Codex ")) return item;
        for (const child of item.children) {
            const found = instrument(child);
            if (found) return found;
        }
        return null;
    }
    Window {
        visible: true; width: 900; height: 32
        Fixture.TopBar { id: bar; anchors.fill: parent; screen: ({name:"fixture"}); visibilities: ({launcher:false}) }
    }
    Component.onCompleted: {
        AgentUsage.codexRequestTimeoutMs = 400; // Shorten the deadline, not the shared poll.
        Fixture.Config.bar.telemetry.showCodexWeekly = true;
    }
    Timer {
        running: true; repeat: true; interval: 15
        onTriggered: {
            const meter = root.instrument(bar);
            if (!meter) return;
            const dial = meter.children.find(child => child.usedPercent !== undefined);
            if (!dial) return;
            const state = () => `${meter.text} / ${dial.usedPercent} / ${meter.Accessible.name}`;
            if (root.phase === 0 && dial.usedPercent === 1) {
                console.log("VALID", state());
                root.issuedAt = Date.now();
                AgentUsage.refresh(); // The CLI receives this request but remains silent.
                root.phase++;
            } else if (root.phase === 1 && Date.now() - root.issuedAt >= 100) {
                console.log("PENDING", state());
                root.phase++;
            } else if (root.phase === 2 && dial.usedPercent === -1) {
                console.log("EXPIRED", state());
                AgentUsage.refresh(); // Same operation as the next scheduled poll.
                console.log("RETRY", dial.usedPercent);
                root.phase++;
            } else if (root.phase === 3 && dial.usedPercent === 3) {
                console.log("RECOVERED", state());
                console.log("QUOTA_OK"); Qt.quit();
            }
        }
    }
    Timer { running: true; interval: 2500; onTriggered: {
        console.log("WATCHDOG", root.phase, root.instrument(bar)?.text); Qt.quit();
    } }
}
