pragma ComponentBehavior: Bound

import qs.components
import qs.services
// import qs.components.effects
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property int index
    required property var occupied
    required property int groupOffset
    required property int focusedWindowId
    required property int activeWsId

    required property Item windowPopoutSignal

    readonly property bool isWorkspace: true // Flag for finding workspace children
    readonly property int size: implicitHeight + (hasWindows ? Appearance.padding.small : 0)
    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows

    // To make the windows repopulate, for Niri.
    // onGroupOffsetChanged: {
    //     windows.active = false;
    //     windows.active = true;
    // }

    Behavior on scale {
        Anim {}
    }

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: size

    spacing: 0

    Item {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        Layout.preferredHeight: Config.bar.sizes.innerWidth - Appearance.padding.small * 2

        Layout.preferredWidth: indicator.width

        StyledText {
            id: indicator

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            animate: true
            text: {
                //TODO: Add config option to choose between name/number/both for workspaces

                const wsName = Niri.getWorkspaceNameByIndex(root.index) || (root.ws);
                const label = Config.bar.workspaces.label || root.ws;
                const occupiedLabel = Config.bar.workspaces.occupiedLabel || label;
                const activeLabel = root.activeWsId || (root.isOccupied ? occupiedLabel : label);
                return root.activeWsId === root.ws ? activeLabel : root.isOccupied ? occupiedLabel : label;
            }

            color: root.activeWsId === root.ws ? Colours.palette.m3onPrimary : (root.isOccupied ? Colours.palette.m3onSurface : Colours.palette.m3outlineVariant)
            verticalAlignment: Qt.AlignVCenter
        }

        Loader {

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.right
            anchors.leftMargin: Appearance.padding.large

            active: (Niri.wsContextType === "workspace" && Niri.wsContextAnchor === root) || Niri.wsContextType === "workspaces" && Niri.wsContextAnchor
            sourceComponent: StyledText {
                color: root.activeWsId === root.ws ? Colours.palette.m3onPrimary // <--- customize to your active color
                 : (root.isOccupied ? Colours.palette.m3onSurface : Colours.palette.m3outlineVariant)

                font.family: Appearance.font.family.mono
                text: Niri.getWorkspaceNameByIndex(root.index) || "Workspace " + (root.index + 1)
            }
        }

        MouseArea {
            id: interaction
            anchors.fill: parent
            propagateComposedEvents: true
            preventStealing: true

            // hoverEnabled: true

            cursorShape: Qt.PointingHandCursor

            acceptedButtons: Qt.RightButton | Qt.LeftButton

            onPressed: event => {
                if (event.button === Qt.RightButton) {
                    // const thing = layout.childAt(event.x, event.y);
                    const thing = root;
                    const winds = Niri.getWindowsByWorkspaceIndex(thing.index);

                    if (thing && winds) {
                        Niri.wsContextAnchor = thing;
                        Niri.wsContextType = "workspace";
                        root.windowPopoutSignal.requestWindowPopout();
                    }
                    return;
                }
                if (event.button === Qt.LeftButton) {
                    // const thing = layout.childAt(event.x, event.y);
                    const thing = root;
                    const ws = thing.index + root.groupOffset;
                    if (Niri.focusedWorkspaceId + 1 !== ws)
                        Niri.switchToWorkspaceByIndex(ws);
                    return;
                }
            }
        }
    }

    Loader {
        id: windows

        Layout.alignment: Qt.AlignHCenter
        // Layout.fillHeight: true
        Layout.topMargin: -Config.bar.sizes.innerWidth / 10

        visible: active
        active: root.hasWindows
        asynchronous: true

        sourceComponent: DraggableWindowColumn {
            id: dragDropLayout
            spacing: 0

            workspace: root
            focusedWindowId: root.focusedWindowId
            activeWsId: root.activeWsId
            ws: root.ws
            windowPopoutSignal: root.windowPopoutSignal
            idx: root.index
            groupOffset: root.groupOffset
        }
    }

    Behavior on Layout.preferredHeight {
        Anim {}
    }
}
