pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// GameMode - low-distraction toggle for gaming sessions.
//
// While enabled: screen stays on (idle inhibitor) and the papertoy
// background engine is parked. Previous states are restored on exit.
// ScreensaverService reads Papertoy state live, so lock/unlock cycles
// during a session behave normally.
Singleton {
    id: root

    property alias enabled: props.enabled
    property bool savedPapertoy: false
    property bool savedInhibitor: false

    PersistentProperties {
        id: props

        property bool enabled

        reloadableId: "gameMode"
    }

    Component.onCompleted: {
        if (root.enabled)
            root.apply();
    }

    onEnabledChanged: {
        if (root.enabled)
            root.apply();
        else
            root.restore();
    }
    function ensureLoaded(): void {
    }

    function apply(): void {
        root.savedPapertoy = Papertoy.enabled;
        root.savedInhibitor = IdleInhibitor.enabled;
        Papertoy.enabled = false;
        IdleInhibitor.enabled = true;
    }

    function restore(): void {
        Papertoy.enabled = root.savedPapertoy;
        IdleInhibitor.enabled = root.savedInhibitor;
    }

    IpcHandler {
        target: "gameMode"

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
