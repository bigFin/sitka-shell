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
    readonly property string screenName: root.screen?.name ?? ""
    readonly property int indicatorSerial: WorkspaceIndicatorModel.targetSerial
    readonly property var indicatorTargets: {
        void indicatorSerial;
        return WorkspaceIndicatorModel.getTargetsForOutput(root.screenName);
    }
    readonly property var myWorkspaces: WorkspaceModel.getWorkspacesForOutput(root.screenName)

    // Active index within the filtered list
    readonly property int activeWsIndex: {
        void indicatorSerial;
        const activeId = indicatorTargets.active?.workspaceId ?? "";
        return myWorkspaces.findIndex(w => String(w.id) === String(activeId));
    }

    readonly property string activeWsId: String(indicatorTargets.active?.workspaceId ?? "")
    readonly property string focusedWindowWorkspaceId: String(indicatorTargets.focusedWindow?.workspaceId ?? "")

    readonly property var occupied: WorkspaceModel.workspaceHasWindows
    // Paging not fully implemented for multi-monitor yet, assuming fit-all or use existing logic if needed. 
    // For now using simple list.
    readonly property int groupOffset: 0 

    readonly property string focusedWindowId: String(indicatorTargets.focusedWindow?.windowId ?? "")

    implicitHeight: layout.implicitHeight + Config.appearance.padding.small * 2
    implicitWidth: Config.bar.sizes.innerWidth

    color: Colours.tPalette.m3surfaceContainer
    radius: Config.appearance.rounding.normal

    signal requestWindowPopout

    Connections {
        target: WMService
        function onWsContextTypeChanged() {
            if (WMService.wsContextType === "workspaces") {
                WMService.wsContextAnchor = root;
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
        active: Config.bar.workspaces.windowRighClickContext && WMService.wsContextType !== "none"
        asynchronous: true

        anchors.left: parent.left
        anchors.leftMargin: Config.appearance.padding.small

        z: WMService.wsContextType === "workspaces" ? -10 : 0

        sourceComponent: ContextBg {
            groupOffset: root.groupOffset
            wsOffset: root.y
            anchorWs: WMService.wsContextAnchor
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
            activeWorkspaceId: root.activeWsId
            focusedWindowWorkspaceId: root.focusedWindowWorkspaceId
            focusedWindowId: root.focusedWindowId
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
                focusedWindowWorkspaceId: root.focusedWindowWorkspaceId
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
