import qs.widgets
import qs.services
import qs.utils
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property int index
    required property var occupied
    required property int groupOffset

    readonly property bool isWorkspace: true // Flag for finding workspace children
    // Unanimated prop for others to use as reference
    readonly property real size: childrenRect.height + (hasWindows ? Appearance.padding.smaller : 0)

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows

    Layout.preferredWidth: childrenRect.width
    Layout.preferredHeight: size

    StyledText {
        id: indicator

        readonly property string label: Config.bar.workspaces.label || root.ws
        readonly property string occupiedLabel: Config.bar.workspaces.occupiedLabel || label
        readonly property string activeLabel: /*Config.bar.workspaces.activeLabel*/ Niri.focusedWorkspaceIndex + 1 || (root.isOccupied ? occupiedLabel : label)

        animate: true
        text: Niri.focusedWorkspaceIndex + 1 === root.ws ? activeLabel : root.isOccupied ? occupiedLabel : label
        color: Config.bar.workspaces.occupiedBg || root.isOccupied || Niri.focusedWorkspaceIndex + 1 === root.ws ? Colours.palette.m3onSurface : Colours.palette.m3outlineVariant
        horizontalAlignment: StyledText.AlignHCenter
        verticalAlignment: StyledText.AlignVCenter

        width: Config.bar.sizes.innerHeight
        height: Config.bar.sizes.innerHeight
    }

    Loader {
        id: windows

        active: Config.bar.workspaces.showWindows
        asynchronous: true

        anchors.horizontalCenter: indicator.horizontalCenter
        anchors.top: indicator.bottom
        anchors.topMargin: -Config.bar.sizes.innerHeight / 10

        sourceComponent: Column {
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

                    // New Niri implementation:
                    readonly property int targetWorkspaceId: {
                        const niriWorkspace = Niri.allWorkspaces[root.index + root.groupOffset];
                        // Return its ID
                        return niriWorkspace.id;
                    }

                    values: Niri.windows.filter(c => c.workspace_id === targetWorkspaceId)
                }
                
                
                MaterialIcon {
                    required property var modelData

                    grade: 0
                    text: Icons.getAppCategoryIcon(modelData.app_id, "terminal")
                    color: Niri.focusedWindow.id === modelData.id ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant 
                    
                    // Behavior on font.pointSize {
                    // }

                    MouseArea {
                        anchors.fill: parent // Make the MouseArea cover the entire icon area
                        acceptedButtons: Qt.LeftButton // | Qt.LeftButton Accept both left and right clicks
                        cursorShape: Qt.PointingHandCursor

                        onClicked: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                
                                console.log("Right-clicked on window:", modelData.title, "ID:", modelData.id);
                                if (modelData && Niri.focusWindow) {
                                    Niri.focusWindow(modelData.id); 
                                }
                            }
                            //  else if (mouse.button === Qt.LeftButton) {
                            //     // Optional: Handle left-click, e.g., move to window's workspace if not focused
                            //     console.log("Left-clicked on window:", modelData.title, "ID:", modelData.id);
                            //     // Example: if not focused, switch to its workspace
                            //     if (modelData && modelData.workspace_id !== Niri.focusedWorkspaceIndex + 1) {
                            //         // You might need a Niri function to switch to a specific workspace ID,
                            //         // or iterate Niri.allWorkspaces to find the index.
                            //         // Assuming Niri has a way to switch by workspace_id or focus a window to switch.
                            //         Niri.focusWindow(modelData); // Focusing the window usually switches to its workspace.
                            //     }
                            // }
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
