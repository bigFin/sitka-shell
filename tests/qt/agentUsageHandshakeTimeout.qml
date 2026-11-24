import QtQuick
import Quickshell
import qs.services

ShellRoot {
    Component.onCompleted: {
        AgentUsage.codexRequestTimeoutMs = 400;
        AgentUsage.addCodexView();
    }
    Connections {
        target: AgentUsage
        function onCodexErrorChanged(): void {
            if (AgentUsage.codexError === "Codex request timed out") {
                console.log("HANDSHAKE_EXPIRED");
                retry.start();
            } else if (AgentUsage.codexError === "Already initialized") {
                console.log(AgentUsage.codexError);
                Qt.quit();
            }
        }
        function onCodexWeeklyQuotaChanged(): void {
            if (AgentUsage.codexWeeklyQuota?.usedPercent === 1 && !AgentUsage.codexError) {
                console.log("QUOTA_OK");
                Qt.quit();
            }
        }
    }
    // If the expired process is reused, its successful reply has already arrived by this retry.
    Timer { id: retry; interval: 600; onTriggered: AgentUsage.refresh() }
    Timer { running: true; interval: 2500; onTriggered: Qt.quit() }
}