pragma Singleton
import Quickshell
import Quickshell.Wayland
import QtQuick

Singleton {
    id: root

    readonly property bool isIdle: idleMonitor.isIdle
    property int idleThresholdSeconds: 300

    signal idleChanged(bool idle)

    IdleMonitor {
        id: idleMonitor

        timeout: root.idleThresholdSeconds
        onIsIdleChanged: root.idleChanged(isIdle)
    }
}
