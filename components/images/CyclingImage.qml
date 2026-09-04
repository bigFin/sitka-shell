pragma ComponentBehavior: Bound

import Quickshell.Io
import QtQuick

// CyclingImage shows a static fallback image, or rotates through every
// image in a directory on an interval. With no dir (or a non-positive
// interval) it behaves exactly like a plain Image.
Image {
    id: root

    property string dir: ""
    property string fallbackSource: ""
    property int cycleSeconds: 0
    readonly property int entryCount: files.entries.length
    property int cycleIndex: 0

    asynchronous: true
    source: {
        if (!root.dir || root.cycleSeconds <= 0 || files.entries.length === 0)
            return root.fallbackSource;
        return files.entries[root.cycleIndex % files.entries.length]?.path ?? root.fallbackSource;
    }

    Timer {
        running: !!root.dir && root.cycleSeconds > 0 && files.entries.length > 1
        interval: Math.max(1, root.cycleSeconds) * 1000
        repeat: true
        onTriggered: root.cycleIndex++
    }

    FileSystemModel {
        id: files

        recursive: false
        path: root.dir
        filter: FileSystemModel.Images
    }
}
