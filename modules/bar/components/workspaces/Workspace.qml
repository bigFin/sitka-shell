pragma ComponentBehavior: Bound

import qs.components
import "../../../../config"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var workspaceData
    required property int index
    required property var occupied
    required property int groupOffset
    required property string focusedWindowId
    required property string focusedWindowWorkspaceId
    required property string activeWsId

    required property Item windowPopoutSignal

    readonly property bool isWorkspace: true // Flag for finding workspace children
    readonly property int size: isWorkspace ? implicitHeight + (hasWindows ? Config.appearance.padding.small : 0) : 0

    readonly property int wsIdx: workspaceData.idx
    readonly property string wsId: String(workspaceData.id)
    readonly property int ws: wsIdx // Alias for compatibility with other components expecting 'ws'

    readonly property bool isOccupied: occupied[wsIdx] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows

    readonly property real activeWindowCenterY: {
        if (!hasFocusedWindow || windows.status !== Loader.Ready || !windows.item)
            return size / 2;
        return windows.y + windows.item.activeWindowY;
    }
    readonly property bool hasFocusedWindow: root.wsId === root.focusedWindowWorkspaceId && windows.status === Loader.Ready && windows.item && windows.item.hasFocusedWindow

    Behavior on scale {
        Anim {}
    }

    Behavior on Layout.preferredHeight {
        Anim {}
    }

    Layout.alignment: Qt.AlignLeft
    Layout.preferredHeight: size

    spacing: 0

    WorkspaceIcon {
        workspace: root
    }

    Loader {
        id: windows

        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: -Config.bar.sizes.innerWidth / 10

        visible: active
        active: root.hasWindows
        asynchronous: true

        sourceComponent: DraggableWindowColumn {
            id: dragDropLayout
            spacing: 0

            workspaceData: root.workspaceData
            workspace: root
            focusedWindowId: root.focusedWindowId
            activeWsId: root.activeWsId
            ws: root.ws
            windowPopoutSignal: root.windowPopoutSignal
            idx: root.index
            groupOffset: root.groupOffset
        }
    }
}
