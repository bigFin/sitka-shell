pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property int index
    required property var occupied
    required property int groupOffset
    required property int focusedWindowId

    required property Item windowPopoutSignal

    readonly property bool workspacesPopoutActive: false

    readonly property bool isWorkspace: true // Flag for finding workspace children
    // Unanimated prop for others to use as reference
    readonly property real size: childrenRect.height + (hasWindows ? Appearance.padding.smaller : 0)

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows

    readonly property int currentWorkspace: Niri.focusedWorkspaceIndex + 1 // + 1 cuz Niri index starts with 0 this needs 1.

    Layout.preferredWidth: childrenRect.width
    Layout.preferredHeight: size

    // To make the windows repopulate.

    onGroupOffsetChanged: {
        windows.active = false;
        windows.active = true;
    }

    StyledText {
        id: indicator

        readonly property string label: Config.bar.workspaces.label || root.ws
        readonly property string occupiedLabel: Config.bar.workspaces.occupiedLabel || label
        readonly property string activeLabel: root.currentWorkspace || (root.isOccupied ? occupiedLabel : label)

        animate: true
        text: root.currentWorkspace === root.ws ? activeLabel : root.isOccupied ? occupiedLabel : label

        color: root.currentWorkspace === root.ws ? Colours.palette.m3onPrimary // <--- customize to your active color
         : (root.isOccupied ? Colours.palette.m3onSurface : Colours.palette.m3outlineVariant)

        horizontalAlignment: StyledText.AlignHCenter
        verticalAlignment: StyledText.AlignVCenter

        width: Config.bar.sizes.innerWidth
        height: Config.bar.sizes.innerWidth

        MouseArea {
            anchors.fill: parent

            z: -1
            acceptedButtons: Qt.RightButton
            onPressed: event => {
                if (event.button === Qt.RightButton) {
                    const thing = windows.childAt(event.x, event.y);
                    Niri.wsAnchorItem = thing;
                }
            }
        }
    }

    Loader {
        id: windows

        active: Config.bar.workspaces.showWindows
        asynchronous: true

        anchors.horizontalCenter: indicator.horizontalCenter
        anchors.top: indicator.bottom
        anchors.topMargin: -Config.bar.sizes.innerWidth / 10

        sourceComponent: Item {
            id: cocol
            height: col.height
            width: col.width

            Column {
                id: col
                spacing: 0

                add: Transition {
                    Anim {
                        properties: "scale"
                        from: 0
                        to: 1
                        easing.bezierCurve: Appearance.anim.curves.standardDecel
                    }
                }

                move: Transition {
                    Anim {
                        properties: "scale"
                        to: 1
                        easing.bezierCurve: Appearance.anim.curves.standardDecel
                    }
                    Anim {
                        properties: "x,y"
                    }
                }

                Repeater {
                    model: ScriptModel {
                        // WARNING DEFAULT:
                        // values: Niri.toplevels.filter(c => c.workspace_id === root.ws)

                        readonly property int targetWorkspaceId: {
                            const niriWorkspace = Niri.currentOutputWorkspaces[root.index + root.groupOffset];
                            return niriWorkspace.id;
                        }

                        values: Config.bar.workspaces.groupIconsByApp ? (() => {
                                const wsId = targetWorkspaceId;
                                const windows = Niri.windows.filter(w => w.workspace_id === wsId);
                                const groups = {};
                                for (let w of windows) {
                                    const aid = w.app_id || "unknown";
                                    if (!groups[aid])
                                        groups[aid] = [];
                                    groups[aid].push(w);
                                }
                                return Object.keys(groups).map(app_id => ({
                                            app_id,
                                            windows: groups[app_id]
                                        }));
                            })() : Niri.windows.filter(c => c.workspace_id === targetWorkspaceId)

                        // .slice(0, Config.bar.workspaces.shown) //max windows shown
                    }

                    WindowGroupIcon {
                        id: wgIcon

                        required property var modelData

                        windowData: Config.bar.workspaces.groupIconsByApp ? (modelData.windows.find(w => w.id === root.focusedWindowId) || modelData.windows[0]) : modelData
                        windowCount: Config.bar.workspaces.groupIconsByApp ? modelData.windows.length : 1
                        groupWindows: Config.bar.workspaces.groupIconsByApp ? modelData.windows : [modelData]
                        isFocused: Config.bar.workspaces.groupIconsByApp ? modelData.windows.some(w => w.id === root.focusedWindowId) : root.focusedWindowId === modelData.id
                        isWsFocused: root.currentWorkspace === root.ws
                        useImageIcon: Config.bar.workspaces.windowIconImage
                        onRequestPopup: (windows, iconItem) => {
                            Niri.wsItemWindows = windows;
                            Niri.wsAnchorItem = iconItem;
                            // groupPopup.visible = groupPopup.visible ? false : true;
                            root.windowPopoutSignal.requestWindowPopout(); // Only right-click triggers the signal!
                        }
                    }
                }
            }
        }
    }

    Behavior on Layout.preferredWidth {
        Anim {}
    }

    Behavior on Layout.preferredHeight {
        Anim {}
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
