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
    property var codexQuotas: []
    property var claudeQuota: null
    property bool codexLoading: false
    property bool claudeLoading: false
    property string codexError: ""
    property string claudeError: ""
    property double lastUpdatedMs: 0

    property int nextCodexRequestId: 1
    property int codexInitializeRequestId: 0
    property double codexInitializeSentMs: 0
    property int codexRateLimitRequestId: 0
    property double codexRateLimitSentMs: 0
    property int activeViewCount: 0
    readonly property bool pollingActive: activeViewCount > 0

    function refresh(): void {
        if (Config.services.agentUsage.showCodex)
            refreshCodex();
        if (Config.services.agentUsage.showClaude)
            refreshClaude();
    }

    function addView(): void {
        activeViewCount++;
        if (activeViewCount === 1)
            refresh();
    }

    function removeView(): void {
        activeViewCount = Math.max(0, activeViewCount - 1);
    }

    function refreshCodex(): void {
        if (!Config.services.agentUsage.showCodex) {
            codexLoading = false;
            codexError = "";
            rebuildProviders();
            return;
        }
        codexLoading = true;
        codexError = "";
        if (!codexProcess.running) {
            codexProcess.running = true;
        } else if (!codexInitialized) {
            if (ShellParse.isRequestStale(Date.now(), codexInitializeSentMs, 120000)) {
                codexInitializeRequestId = 0;
                codexInitializeSentMs = 0;
                initializeCodex();
            }
        } else {
            if (ShellParse.isRequestStale(Date.now(), codexRateLimitSentMs, 120000))
                codexRateLimitRequestId = 0;
            requestCodexRateLimits();
        }
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

    function initializeCodex(): void {
        codexInitializeRequestId = nextCodexRequestId++;
        codexInitializeSentMs = Date.now();
        sendCodex({
            "id": codexInitializeRequestId,
            "method": "initialize",
            "params": {
                "clientInfo": {
                    "name": "sitka-shell",
                    "version": "1"
                }
            }
        });
    }

    function requestCodexRateLimits(): void {
        if (!codexInitialized || codexRateLimitRequestId !== 0)
            return;
        codexRateLimitRequestId = nextCodexRequestId++;
        codexRateLimitSentMs = Date.now();
        sendCodex({
            "id": codexRateLimitRequestId,
            "method": "account/rateLimits/read"
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
            if (target.showCodex && root.pollingActive)
                root.refreshCodex();
        }

        function onShowAdditionalCodexLimitsChanged(): void {
            root.rebuildProviders();
        }

        function onShowClaudeChanged(): void {
            root.rebuildProviders();
            if (target.showClaude && root.pollingActive)
                root.refreshClaude();
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

        onStarted: root.initializeCodex()
        onExited: {
            root.codexInitialized = false;
            root.codexInitializeRequestId = 0;
            root.codexInitializeSentMs = 0;
            root.codexRateLimitRequestId = 0;
            root.codexRateLimitSentMs = 0;
            root.codexLoading = false;
            if (root.codexQuotas.length === 0)
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

                if (message.id === root.codexInitializeRequestId) {
                    root.codexInitializeRequestId = 0;
                    if (message.error) {
                        root.codexLoading = false;
                        root.codexError = message.error.message || qsTr("Codex initialization failed");
                        return;
                    }
                    root.codexInitialized = true;
                    root.sendCodex({"method": "initialized"});
                    root.requestCodexRateLimits();
                    return;
                }

                if (message.id === root.codexRateLimitRequestId) {
                    root.codexRateLimitRequestId = 0;
                    if (message.error) {
                        root.codexLoading = false;
                        root.codexError = message.error.message || qsTr("Codex quota request failed");
                        return;
                    }
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
