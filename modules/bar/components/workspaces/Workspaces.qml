pragma ComponentBehavior: Bound

import qs.services
import qs.config
import qs.components
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    readonly property list<Workspace> workspaces: layout.children.filter(c => c.isWorkspace).sort((w1, w2) => w1.ws - w2.ws)
    readonly property var occupied: Niri.workspaceHasWindows
    readonly property int groupOffset: Math.floor((Niri.focusedWorkspaceIndex) / Config.bar.workspaces.shown) * Config.bar.workspaces.shown
    readonly property int focusedWindowId: Niri.focusedWindow.id

    implicitWidth: layout.implicitWidth + Appearance.padding.small * 2
    implicitHeight: layout.implicitHeight + Appearance.padding.small * 2
    color: Colours.tPalette.m3surfaceContainer
    radius: Appearance.rounding.full

    signal requestWindowPopout

    Item {
        id: inner

        anchors.fill: parent
        anchors.margins: Appearance.padding.small

        ColumnLayout {
            id: layout

            spacing: 0
            layer.enabled: true
            layer.smooth: true

            Repeater {
                model: Config.bar.workspaces.shown > Niri.getWorkspaceCount() ? Niri.getWorkspaceCount() : Config.bar.workspaces.shown

                Workspace {
                    occupied: root.occupied
                    groupOffset: root.groupOffset
                    focusedWindowId: root.focusedWindowId
                    windowPopoutSignal: root
                }
            }
        }

        Loader {
            active: Config.bar.workspaces.occupiedBg
            asynchronous: true

            z: -1
            anchors.fill: parent

            sourceComponent: OccupiedBg {
                workspaces: root.workspaces
                occupied: root.occupied
                groupOffset: root.groupOffset
            }
        }

        Loader {
            id: pager
            active: Config.bar.workspaces.shown < Niri.getWorkspaceCount()

            anchors.top: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            z: -1

            sourceComponent: Pager {
                groupOffset: root.groupOffset
            }
        }

        Loader {
            active: Config.bar.workspaces.activeIndicator
            asynchronous: true

            z: -1

            sourceComponent: ActiveIndicator {
                workspaces: root.workspaces
                // mask: layout
                // maskWidth: inner.width
                // maskHeight: inner.height
                groupOffset: root.groupOffset
            }
        }

        Loader {
            // Right click on window context menu
            active: Config.bar.workspaces.windowRighClickContext
            asynchronous: true

            z: -1

            anchors.right: parent.right
            anchors.rightMargin: -Appearance.padding.small

            sourceComponent: ContextBg {
                groupOffset: root.groupOffset
                wsOffset: root.y
            }
        }

        MouseArea {
            anchors.fill: parent

            z: -1

            onPressed: event => {
                const ws = layout.childAt(event.x, event.y).index + root.groupOffset + 1;
                if (Niri.focusedWorkspaceId + 1 !== ws)
                    Niri.switchToWorkspace(ws);
            }
        }
    }
}
