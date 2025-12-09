pragma ComponentBehavior: Bound

import qs.components
import qs.services
import "../../../config"
import qs.modules.windowinfo
import qs.modules.controlcenter
import Quickshell
import Quickshell.Wayland
import QtQuick

Item {
    id: root

    required property ShellScreen screen

    readonly property real nonAnimWidth: x > 0 || hasCurrent ? children.find(c => c.shouldBeActive)?.implicitWidth ?? content.implicitWidth : 0
    readonly property real nonAnimHeight: children.find(c => c.shouldBeActive)?.implicitHeight ?? content.implicitHeight

    property string currentName
    property real currentCenter
    property bool hasCurrent

    property string detachedMode
    property string queuedMode
    readonly property bool isDetached: detachedMode.length > 0

    // Synchronized buttress animation
    property real buttressSize: (hasCurrent && !isDetached) ? Config.appearance.fillet.large : 0
    Behavior on buttressSize {
        Anim {
            duration: root.animLength
            easing.bezierCurve: root.animCurve
        }
    }

    property int animLength: Config.appearance.anim.durations.normal
    property list<real> animCurve: Config.appearance.anim.curves.emphasized

    function detach(mode: string): void {
        animLength = Config.appearance.anim.durations.large;
        if (mode === "winfo") {
            detachedMode = mode;
        } else {
            detachedMode = "any";
            queuedMode = mode;
        }
        focus = true;
    }

    function close(): void {
        hasCurrent = false;
        animLength = Config.appearance.anim.durations.normal;
        detachedMode = "";
    }

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    Keys.onEscapePressed: close()

    // HyprlandFocusGrab {
    //     active: root.isDetached
    //     windows: [QsWindow.window]
    //     onCleared: root.close()
    // }

    Binding {
        when: root.isDetached

        target: QsWindow.window
        property: "WlrLayershell.keyboardFocus"
        value: WlrKeyboardFocus.OnDemand
    }

    Comp {
        id: content

        shouldBeActive: root.hasCurrent && !root.detachedMode
        asynchronous: true
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        sourceComponent: Content {
            wrapper: root
        }
    }

    Comp {
        shouldBeActive: root.detachedMode === "winfo"
        asynchronous: true
        anchors.centerIn: parent

        sourceComponent: WindowInfo {
            screen: root.screen
            client: WMService.focusedWindow
            wrapper: root
        }
    }

    Comp {
        shouldBeActive: root.detachedMode === "any"
        asynchronous: true
        anchors.centerIn: parent

        sourceComponent: ControlCenter {
            screen: root.screen
            active: root.queuedMode

            function close(): void {
                root.close();
            }
        }
    }

    Behavior on x {
        Anim {
            duration: root.animLength
            easing.bezierCurve: root.animCurve
        }
    }

    Behavior on y {
        enabled: root.implicitWidth > 0

        Anim {
            duration: root.animLength
            easing.bezierCurve: root.animCurve
        }
    }

    Behavior on implicitWidth {
        Anim {
            duration: root.animLength
            easing.bezierCurve: root.animCurve
        }
    }

    Behavior on implicitHeight {
        enabled: root.implicitWidth > 0

        Anim {
            duration: root.animLength
            easing.bezierCurve: root.animCurve
        }
    }

    component Comp: Loader {
        id: comp

        property bool shouldBeActive

        asynchronous: true
        active: true
        opacity: 0
        visible: opacity > 0

        states: State {
            name: "active"
            when: comp.shouldBeActive

            PropertyChanges {
                comp.opacity: 1
            }
        }

        transitions: [
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    Anim {
                        property: "opacity"
                    }
                }
            },
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    Anim {
                        property: "opacity"
                    }
                }
            }
        ]
    }
    // for debug
    // Component.onCompleted: {
    // root.detach("winfo");
    // }
}
