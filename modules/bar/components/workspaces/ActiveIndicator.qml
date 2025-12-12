pragma ComponentBehavior: Bound
import qs.components
import qs.services
import "../../../../config"
import QtQuick

StyledRect {
    id: root

    required property int activeWsIndex
    required property Repeater workspaces
    required property Item mask
    required property int groupOffset
    
    // Apply small fillets for tertiary elements
    filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.small : 2

    readonly property int currentWsIdx: {
        let i = activeWsIndex;
        while (i < 0)
            i += Config.bar.workspaces.shown;
        return i % Config.bar.workspaces.shown;
    }
    onCurrentWsIdxChanged: {
        lastWs = cWs;
        cWs = currentWsIdx;
    }

    property int cWs
    property int lastWs

    // Geometry tracking
    property real leading: workspaces.itemAt(currentWsIdx)?.y ?? 0
    property real trailing: workspaces.itemAt(currentWsIdx)?.y ?? 0

    property real currentSize: workspaces.itemAt(currentWsIdx)?.size ?? 0
    property real offset: Math.min(leading, trailing)

    property real size: {
        const s = Math.abs(leading - trailing) + currentSize;
        if (Config.bar.workspaces.activeTrail && lastWs > currentWsIdx) {
            const ws = workspaces.itemAt(lastWs);
            return ws ? Math.min(ws.y + ws.size - offset, s) : 0;
        }
        return s;
    }

    property bool isContextActiveInWs: (WMService.wsContextType === "workspace" && WMService.wsContextAnchor?.index === root.currentWsIdx)
    property bool isWorkspacesContextActive: (WMService.wsContextType === "workspaces") && WMService.wsContextAnchor
    clip: false
    y: offset + mask.y
    implicitHeight: size
    radius: Config.appearance.rounding.small
    color: Qt.alpha(Colours.palette.m3primary, 0.95)

    anchors {
        left: parent.left
        right: parent.right
        leftMargin: Config.appearance.padding.small
        rightMargin: isWorkspacesContextActive ? -Config.bar.workspaces.windowContextWidth + Config.appearance.padding.small * 2 : Config.appearance.padding.small
        Behavior on rightMargin {
            EAnim {}
        }
    }

    Behavior on radius {
        EAnim {}
    }

    Loader {
        id: blob
        active: Config.bar.workspaces.focusedWindowBlob || root.isContextActiveInWs

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: computeMargins().left
            rightMargin: computeMargins().right
            Behavior on leftMargin {
                Anim {}
            }
            Behavior on rightMargin {
                Anim {}
            }
        }

        function computeMargins() {
            if (!WMService.focusedWindowId)
                return {
                    left: Config.appearance.padding.small,
                    right: Config.appearance.padding.small
                };

            if (root.isContextActiveInWs && !root.isWorkspacesContextActive)
                return {
                    left: -Config.appearance.padding.small / 2,
                    right: -Config.bar.workspaces.windowContextWidth - Config.appearance.padding.small / 2
                };

            return {
                left: -Config.appearance.padding.small / 2,
                right: -Config.appearance.padding.small / 2
            };
        }

        sourceComponent: StyledRect {
            id: activeWindowIndicator
            height: WMService.focusedWindowId ? Config.bar.workspaces.windowIconSize + Config.appearance.padding.normal : 0
            width: WMService.focusedWindowId ? Config.bar.workspaces.windowIconSize + Config.appearance.padding.normal : 0
            color: Colours.palette.term13
            filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.small : 2
            anchors.horizontalCenter: parent.horizontalCenter

            y: computeFocusedY()

            // staggered animations
            Behavior on y {
                Anim {}
            }
            Behavior on height {
                Anim {}
            }
            Behavior on width {
                Anim {}
            }

            function computeFocusedY() {
                const ws = workspaces.itemAt(currentWsIdx);
                if (!ws) return 0;
                
                // Calculate the position relative to the ActiveIndicator
                // ActiveIndicator.y is root.offset relative to the container
                // ws.y is relative to the same container
                // ws.activeWindowCenterY is the center of the window relative to ws.y
                
                // Target Global Y = ws.y + ws.activeWindowCenterY
                // ActiveIndicator Global Y = root.offset
                // Local Y = Target Global Y - ActiveIndicator Global Y
                //         = (ws.y + ws.activeWindowCenterY) - root.offset
                
                return (ws.y + ws.activeWindowCenterY) - root.offset - (height / 2);
            }
        }
    }

    // Trail animations
    Behavior on leading {
        enabled: Config.bar.workspaces.activeTrail
        Anim {}
    }
    Behavior on trailing {
        enabled: Config.bar.workspaces.activeTrail

        EAnim {
            duration: Config.appearance.anim.durations.normal * 2
        }
    }
    Behavior on currentSize {
        enabled: Config.bar.workspaces.activeTrail

        EAnim {}
    }
    Behavior on offset {
        enabled: !Config.bar.workspaces.activeTrail

        EAnim {}
    }
    Behavior on size {
        enabled: !Config.bar.workspaces.activeTrail

        EAnim {}
    }

    component EAnim: Anim {
        easing.bezierCurve: Config.appearance.anim.curves.emphasized
    }
}
