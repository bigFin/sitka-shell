pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real bpm

    Process {
        running: true
        command: ["/usr/lib/caelestia/beat_detector"]
        stdout: SplitParser {
            onRead: data => root.bpm = parseFloat(data)
        }
    }
}
