pragma Singleton

import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    property alias enabled: props.enabled

    PersistentProperties {
        id: props

        property bool enabled

        reloadableId: "papertoy"
    }

    Process {
        running: root.enabled
        command: ["papertoy"].concat([Config.services.papertoy.shaderPath]).concat(Config.services.papertoy.args)
    }

    IpcHandler {
        target: "papertoy"

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