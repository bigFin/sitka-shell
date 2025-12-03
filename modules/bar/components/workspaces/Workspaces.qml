pragma ComponentBehavior: Bound

import qs.services
import "../../../../config"
import qs.components
import Quickshell
import QtQuick
import QtQuick.Layouts

import "context"

StyledRect {
    id: root

    required property ShellScreen screen
    
    // Apply large fillets for primary elements
    filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6

    // Filter workspaces for this screen
    readonly property var myWorkspaces: Niri.allWorkspaces.filter(w => w.output === root.screen.name).sort((a, b) => a.idx - b.idx)
    
    // Active index within the filtered list
    readonly property int activeWsIndex: {
        const idx = myWorkspaces.findIndex(w => w.id == Niri.focusedWorkspaceId);
        return idx; // Returns -1 if focused workspace is not on this screen
    }

    readonly property int activeWsId: Number(Niri.focusedWorkspaceId) || 0

    readonly property var occupied: (Niri && Niri.workspaceHasWindows) ? Niri.workspaceHasWindows : ({})
    // Paging not fully implemented for multi-monitor yet, assuming fit-all or use existing logic if needed. 
    // For now using simple list.
    readonly property int groupOffset: 0 

    readonly property int focusedWindowId: Niri.focusedWindow ? Niri.focusedWindow.id : -1

    implicitHeight: layout.implicitHeight + Config.appearance.padding.small * 2
    implicitWidth: Config.bar.sizes.innerWidth

    color: Colours.tPalette.m3surfaceContainer
    radius: Config.appearance.rounding.normal

    signal requestWindowPopout

    Connections {
        target: Niri
        function onWsContextTypeChanged() {
            if (Niri.wsContextType === "workspaces") {
                Niri.wsContextAnchor = root;
            }
        }
    }

    Loader {
        active: Config.bar.workspaces.occupiedBg
        asynchronous: true

        anchors.fill: parent
        anchors.margins: Config.appearance.padding.small

        sourceComponent: OccupiedBg {
            workspaces: workspaces
            occupied: root.occupied
            groupOffset: root.groupOffset
        }
    }

    Loader {
        // Right click on window context menu
        active: Config.bar.workspaces.windowRighClickContext && Niri.wsContextType !== "none"
        asynchronous: true

        anchors.left: parent.left
        anchors.leftMargin: Config.appearance.padding.small

        z: Niri.wsContextType === "workspaces" ? -10 : 0

        sourceComponent: ContextBg {
            groupOffset: root.groupOffset
            wsOffset: root.y
            anchorWs: Niri.wsContextAnchor
        }
    }

    Loader {
        anchors.left: parent.left
        anchors.right: parent.right
        // Only show indicator if the active workspace is on this screen
        active: Config.bar.workspaces.activeIndicator && root.activeWsIndex >= 0
        asynchronous: true

        sourceComponent: ActiveIndicator {
            activeWsIndex: root.activeWsIndex
            workspaces: workspaces
            mask: layout
            groupOffset: root.groupOffset
        }
    }

    ColumnLayout {
        id: layout

        z: 1

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Config.appearance.padding.small
        spacing: Math.floor(Config.appearance.spacing.small)

        Repeater {
            id: workspaces

            model: root.myWorkspaces

            Workspace {
                required property var modelData
                workspaceData: modelData
                
                activeWsId: root.activeWsId
                occupied: root.occupied
                groupOffset: root.groupOffset
                focusedWindowId: root.focusedWindowId
                windowPopoutSignal: root
            }
        }
    }

    Loader {
        id: pager
        active: Config.bar.workspaces.pagerActive

        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        z: -1

        sourceComponent: Pager {
            groupOffset: root.groupOffset
        }
    }
}