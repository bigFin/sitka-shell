pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false

    Process {
        running: root.enabled
        command: ["systemd-inhibit", "--what=idle", "--mode=block", "sleep", "inf"]
    }

    IpcHandler {
        target: "idleInhibitor"

        function isEnabled(): bool {
            return root.enabled;
        }

        function toggle(): void {
            root.enabled = !root.enabled;
        }

        function enable(): void {
            root.enabled = true;
        }

        function disable(): void {
            root.enabled = false;
        }
    }
}
