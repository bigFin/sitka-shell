pragma ComponentBehavior: Bound

import qs.services
import qs.components
import "../../../../config"
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var workspace
    property bool popupActive: (Niri.wsContextAnchor === root) || (Niri.wsContextAnchor === workspace) || (Niri.wsContextType === "workspaces")

    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
    Layout.preferredHeight: Config.bar.workspaces.windowIconSize + Config.bar.workspaces.windowIconGap

    implicitWidth: Config.bar.workspaces.windowIconSize + Config.bar.workspaces.windowIconGap + (popupActive ? Config.bar.workspaces.windowContextWidth : 0)
    Behavior on implicitWidth {
        Anim {
            easing.bezierCurve: Config.appearance.anim.curves.emphasized
        }
    }

    z: popupActive ? 90 : 0

    RowLayout {
        id: content
        anchors.left: parent.left
        spacing: Config.appearance.padding.small

        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Config.bar.workspaces.windowIconSize + Config.bar.workspaces.windowIconGap
            Layout.preferredHeight: Config.bar.workspaces.windowIconSize + Config.bar.workspaces.windowIconGap

            StyledText {
                id: indicator
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                animate: true
                text: {
                    //TODO: Add config option to choose between name/number/both for workspaces

                    const wsName = root.workspace.workspaceData.name || root.workspace.wsIdx;
                    const label = Config.bar.workspaces.label || root.workspace.wsIdx;
                    const occupiedLabel = Config.bar.workspaces.occupiedLabel || label;
                    const activeLabel = root.workspace.wsIdx || (root.workspace.isOccupied ? occupiedLabel : label);
                    return root.workspace.activeWsId === root.workspace.wsId ? activeLabel : root.workspace.isOccupied ? occupiedLabel : label;
                }

                color: root.workspace.activeWsId === root.workspace.wsId ? Colours.palette.m3onPrimary : (root.workspace.isOccupied ? Colours.palette.m3onSurface : Colours.palette.m3outlineVariant)
                verticalAlignment: Qt.AlignVCenter
            }
        }

        Loader {
            // anchors.verticalCenter: parent.verticalCenter
            // anchors.left: parent.right
            // anchors.leftMargin: Config.appearance.padding.large
            active: root.popupActive
            sourceComponent: StyledText {
                color: root.workspace.activeWsId === root.workspace.ws ? Colours.palette.m3onPrimary // <--- customize to your active color
                 : (root.workspace.isOccupied ? Colours.palette.m3onSurface : Colours.palette.m3outlineVariant)

                font.family: Config.appearance.font.family.mono
                text: root.workspace.workspaceData.name || "Workspace " + root.workspace.ws
            }
        }
        z: 1
    }

    Interaction {
        id: interactionArea
    }

    // --------------------------
    // Interaction / Drag Handling
    // --------------------------
    component Interaction: StateLayer {
        id: mouseArea
        anchors.fill: root
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: (Qt.PointingHandCursor)
        pressAndHoldInterval: Config.appearance.anim.durations.small

        radius: Config.appearance.rounding.small

        hoverEnabled: true

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                const thing = root.workspace;
                const winds = Niri.getWindowsByWorkspaceIndex(thing.index);

                if (thing && winds) {
                    Niri.wsContextAnchor = thing;
                    Niri.wsContextType = "workspace";
                    root.workspace.windowPopoutSignal.requestWindowPopout();
                }
                return;
            }
            if (mouse.button === Qt.LeftButton) {
                const thing = root.workspace;
                const ws = thing.index + root.workspace.groupOffset;
                if (Niri.focusedWorkspaceId + 1 !== ws)
                    Niri.switchToWorkspaceByIndex(ws);
                return;
            }
        }
    }
}
