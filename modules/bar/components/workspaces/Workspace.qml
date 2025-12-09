pragma ComponentBehavior: Bound

import qs.components
// import qs.components.effects
import "../../../../config"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var workspaceData
    required property int index
    required property var occupied
    required property int groupOffset
    required property int focusedWindowId
    required property int activeWsId

    required property Item windowPopoutSignal

    readonly property bool isWorkspace: true // Flag for finding workspace children
    readonly property int size: isWorkspace ? implicitHeight + (hasWindows ? Config.appearance.padding.small : 0) : 0
    
    readonly property int wsIdx: workspaceData.idx
    readonly property int wsId: workspaceData.id
    readonly property int ws: wsIdx // Alias for compatibility with other components expecting 'ws'
    
    readonly property bool isOccupied: occupied[wsIdx] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows

    // Component.onCompleted: console.log(`Workspace Component: idx=${wsIdx}, id=${wsId}, activeWsId=${activeWsId}`)

    // To make the windows repopulate, for Niri.
    // onGroupOffsetChanged: {
    //     windows.active = false;
    //     windows.active = true;
    // }

    // clip: true

    readonly property real activeWindowCenterY: {
        if (windows.status !== Loader.Ready || !windows.item) return 0;
        return windows.y + windows.item.activeWindowY;
    }

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
        // Layout.fillHeight: true
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
