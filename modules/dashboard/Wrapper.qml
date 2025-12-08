pragma ComponentBehavior: Bound

import qs.components
import qs.components.filedialog
import "../../config"
import qs.utils
import qs.services
import Quickshell
import Quickshell.Hyprland
import QtQuick
import Sitka

Item {
    id: root

    property bool expanded: false
    property bool isvisible: false

    property real buttressSize: (visibilities.dashboard || expanded || isvisible) ? Config.appearance.fillet.large : 0
    Behavior on buttressSize {
        Anim {
            duration: Config.appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    required property PersistentProperties visibilities
    readonly property PersistentProperties state: PersistentProperties {
        property int currentTab
        property date currentDate: new Date()

        readonly property FileDialog facePicker: FileDialog {
            title: qsTr("Select a profile picture")
            filterLabel: qsTr("Image files")
            filters: Images.validImageExtensions
            onAccepted: path => {
                console.log("FileDialog accepted path:", path);
                if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                    Quickshell.execDetached(["notify-send", "-a", "sitka-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
                else
                    Quickshell.execDetached(["notify-send", "-a", "sitka-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
            }
        }
    }

    // TODO add a way to dismiss with keyboard.
    // Keys.onEscapePressed: function () {
    //     root.expanded = false;
    //     root.isvisible = false;
    // }

    // Timer to control temporary visibility
    Timer {
        id: flashTimer
        interval: 500 // 0.5 second
        running: false
        repeat: false
        onTriggered: {
            root.isvisible = false;
        }
    }

    Connections {
        target: Niri
        function onFocusedWindowIdChanged() {
            // Show dashboard for 1 second
            if ((!root.visibilities.dashboard && !root.expanded) && Niri.focusedWindowId) {
                root.isvisible = true;
                flashTimer.restart();
            }
        }
    }

    visible: height > 0
    implicitHeight: 0
    implicitWidth: content.implicitWidth

    states: [
        State {
            name: "visible"
            when: root.isvisible || ((root.visibilities.dashboard && Config.dashboard.enabled) && !root.expanded)
            PropertyChanges {
                target: root
                implicitHeight: 45
            }
        },
        State {
            name: "expanded"
            when: (Config.dashboard.enabled) && root.expanded
            PropertyChanges {
                target: root
                implicitHeight: content.implicitHeight
            }
        }
    ]

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitHeight"
                duration: Config.appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitHeight"
                easing.bezierCurve: Config.appearance.anim.curves.emphasized
            }
        },
        Transition {
            from: "*"
            to: "*"

            NumberAnimation {
                target: root
                property: "implicitHeight"
                duration: Config.appearance.anim.durations.expressiveDefaultSpatial
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.appearance.anim.curves.emphasized
            }
        }
    ]

    HyprlandFocusGrab {
        active: !Config.dashboard.showOnHover && root.visibilities.dashboard && Config.dashboard.enabled
        windows: [QsWindow.window]
        onCleared: root.visibilities.dashboard = false
    }

    Loader {
        id: content

        active: true

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        sourceComponent: Content {
            visibilities: root.visibilities
            state: root.state
            // --- MouseArea for hover/click detection ---
            MouseArea {
                id: hoverArea
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right

                height: 50
                // hoverEnabled: true
                preventStealing: true
                // z: 1000
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root.expanded) {
                        root.expanded = true;
                    } else if (root.expanded) {
                        root.expanded = false;
                    }
                }
            }
        }
    }
}
