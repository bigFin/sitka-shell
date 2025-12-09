pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool isNiri: false
    property bool isHyprland: false
    property bool detected: false

    Process {
        id: checkHypr
        command: ["sh", "-c", "echo $HYPRLAND_INSTANCE_SIGNATURE"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    root.isHyprland = true
                    root.detected = true
                    console.log("WMDetector: Hyprland detected")
                } else {
                    checkNiri.running = true
                }
            }
        }
    }

    Process {
        id: checkNiri
        command: ["sh", "-c", "echo $NIRI_SOCKET"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    root.isNiri = true
                    root.detected = true
                    console.log("WMDetector: Niri detected")
                } else {
                    console.error("WMDetector: No compatible WM detected (Niri/Hyprland)")
                }
            }
        }
    }
}
