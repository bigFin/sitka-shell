import QtQuick
import Quickshell
import qs.config
import qs.services

ShellRoot {
    id: root
    property int phase: 0

    Timer {
        running: true; repeat: true; interval: 25
        onTriggered: {
            if (root.phase === 0) {
                if (AgentUsage.pollingActive) return;
                // Honour the Codex service switch even with two wide bars.
                Config.services.agentUsage.showCodex = false;
                AgentUsage.addCodexView();
                AgentUsage.addCodexView();
                if (AgentUsage.pollingActive) return;
                Config.services.agentUsage.showCodex = true;
            } else if (root.phase === 1) {
                if (AgentUsage.codexWeeklyQuota?.usedPercent !== 1) return;
                AgentUsage.addView(); // Just Claude is new demand.
                AgentUsage.removeCodexView();
                AgentUsage.removeCodexView();
                if (!AgentUsage.pollingActive) return;
            } else if (root.phase === 2) {
                if (AgentUsage.claudeLoading) return;
                AgentUsage.addCodexView();
                AgentUsage.removeView();
                if (!AgentUsage.pollingActive) return;
                AgentUsage.refresh(); // A bar-only poll must not read Claude.
            } else if (root.phase === 3) {
                if (AgentUsage.codexWeeklyQuota?.usedPercent !== 2) return;
                AgentUsage.removeCodexView();
                if (AgentUsage.pollingActive) return;
                console.log("QUOTA_OK"); Qt.quit();
            }
            root.phase++;
        }
    }
    Timer { running: true; interval: 2000; onTriggered: Qt.quit() }
}
