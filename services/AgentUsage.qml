pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQuick
import "../utils/scripts/shellParse.js" as ShellParse

Singleton {
    id: root

    readonly property bool available: providers.length > 0
    readonly property bool loading: codexLoading || claudeLoading
    readonly property real highestUsedPercent: {
        let highest = 0;
        for (const provider of providers)
            highest = Math.max(highest, provider.usedPercent);
        return highest;
    }

    property var providers: []
    // Additional model limits (or Claude) can be present without the default Codex week.
    readonly property var codexWeeklyQuota: providers.find(quota => quota.id === "codex-codex") ?? null
    property var codexQuotas: []
    property var claudeQuota: null
    property bool codexLoading: false
    property bool claudeLoading: false
    property string codexError: ""
    property string claudeError: ""
    property double lastUpdatedMs: 0

    property int nextCodexRequestId: 1
    property bool codexInitialized: false
    property var codexPending: null // Only one request (handshake or quota read) is outstanding.
    property int activeViewCount: 0
    property int codexViewCount: 0
    readonly property bool codexWanted: Config.services.agentUsage.showCodex && (activeViewCount > 0 || codexViewCount > 0)
    readonly property bool claudeWanted: Config.services.agentUsage.showClaude && activeViewCount > 0
    readonly property bool pollingActive: codexWanted || claudeWanted

    onCodexWantedChanged: if (codexWanted) refreshCodex()
    onClaudeWantedChanged: if (claudeWanted) refreshClaude()

    function refresh(): void {
        if (codexWanted)
            refreshCodex();
        if (claudeWanted)
            refreshClaude();
    }

    function addView(): void {
        activeViewCount++;
    }

    function removeView(): void {
        activeViewCount = Math.max(0, activeViewCount - 1);
    }

    // Top bars share the dashboard's Codex session, but never request Claude.
    function addCodexView(): void { codexViewCount++; }
    function removeCodexView(): void { codexViewCount = Math.max(0, codexViewCount - 1); }

    function refreshCodex(): void {
        if (!Config.services.agentUsage.showCodex) {
            codexLoading = false;
            codexError = "";
            rebuildProviders();
            return;
        }
        codexLoading = true;
        // Only a successful read makes a cached value current again.
        if (!codexProcess.running)
            codexProcess.running = true;
        else
            requestCodex();
    }

    function refreshClaude(): void {
        if (!Config.services.agentUsage.showClaude) {
            claudeLoading = false;
            claudeError = "";
            rebuildProviders();
            return;
        }
        if (claudeProcess.running)
            return;
        claudeLoading = true;
        claudeError = "";
        claudeProcess.running = true;
    }

    function sendCodex(message: var): void {
        codexProcess.write(JSON.stringify(message) + "\n");
    }

    function requestCodex(): void {
        if (!codexWanted) {
            codexLoading = false;
            return;
        }
        const now = Date.now();
        if (codexPending && !ShellParse.isRequestStale(now, codexPending.sentMs, 120000))
            return;
        const id = nextCodexRequestId++;
        codexPending = { id: id, sentMs: now };
        sendCodex(codexInitialized ? { id: id, method: "account/rateLimits/read" } : {
            id: id, method: "initialize", params: { clientInfo: { name: "sitka-shell", version: "1" } }
        });
    }

    function chooseLongestWindow(snapshot: var): var {
        return ShellParse.chooseLongestWindow(snapshot);
    }

    function parseCodexRateLimits(result: var): void {
        const quotas = ShellParse.extractCodexQuotas(result);
        codexQuotas = quotas;
        codexError = quotas.length > 0 ? "" : qsTr("No weekly Codex quota reported");
        codexLoading = false;
        if (quotas.length > 0)
            lastUpdatedMs = Date.now();
        rebuildProviders();
    }

    function stripTerminalCodes(text: string): string {
        return ShellParse.stripTerminalCodes(text);
    }

    function parseClaudeUsage(text: string): void {
        const parsed = ShellParse.extractClaudeQuota(text);

        claudeLoading = false;
        if (!parsed) {
            claudeError = qsTr("No weekly Claude quota reported");
            return;
        }

        claudeQuota = parsed;
        claudeError = "";
        lastUpdatedMs = Date.now();
        rebuildProviders();
    }

    function rebuildProviders(): void {
        let values = [];
        if (Config.services.agentUsage.showCodex) {
            values = Config.services.agentUsage.showAdditionalCodexLimits
                ? codexQuotas.slice()
                : codexQuotas.filter(quota => quota.id === "codex-codex");
        }
        if (Config.services.agentUsage.showClaude && claudeQuota)
            values.push(claudeQuota);
        providers = values;
    }

    Component.onCompleted: rebuildProviders()

    Connections {
        target: Config.services.agentUsage

        function onShowCodexChanged(): void {
            root.rebuildProviders();
        }

        function onShowAdditionalCodexLimitsChanged(): void {
            root.rebuildProviders();
        }

        function onShowClaudeChanged(): void {
            root.rebuildProviders();
        }
    }

    Timer {
        interval: 60 * 1000
        running: root.pollingActive
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: codexProcess

        command: ["codex", "-s", "read-only", "-a", "untrusted", "app-server"]
        stdinEnabled: true

        onStarted: root.requestCodex()
        // A failed exec has no exited signal; both failure and normal exit clear running.
        onRunningChanged: {
            if (running)
                return;
            root.codexInitialized = false;
            root.codexPending = null;
            root.codexLoading = false;
            root.codexError = qsTr("Codex CLI unavailable");
        }

        stdout: SplitParser {
            onRead: data => {
                let message;
                try {
                    message = JSON.parse(data);
                } catch (error) {
                    return;
                }

                if (!root.codexPending || message?.id !== root.codexPending.id)
                    return;
                root.codexPending = null;
                if (message.error) {
                    root.codexLoading = false;
                    root.codexError = message.error.message || (root.codexInitialized ? qsTr("Codex quota request failed") : qsTr("Codex initialization failed"));
                    return;
                }
                if (!root.codexInitialized) {
                    root.codexInitialized = true;
                    root.sendCodex({"method": "initialized"});
                    root.requestCodex();
                } else {
                    root.parseCodexRateLimits(message.result);
                }
            }
        }
    }

    Process {
        id: claudeProcess

        command: ["timeout", "--signal=TERM", "--kill-after=2s", "10s", "script", "-qfec", "env -u CLAUDE_CODE_OAUTH_TOKEN claude /usage --allowed-tools ''", "/dev/null"]
        workingDirectory: Quickshell.env("HOME")

        onExited: root.claudeLoading = false

        stdout: StdioCollector {
            onStreamFinished: root.parseClaudeUsage(text)
        }
    }
}
