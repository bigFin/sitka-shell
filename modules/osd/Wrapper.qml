import qs.components
import qs.services
import "../../config"
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property var visibilities

    property real buttressSize: (visibilities.osd && Config.osd.enabled) ? Config.appearance.fillet.large : 0
    Behavior on buttressSize {
        Anim {
            duration: Config.appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    visible: width > 0
    implicitWidth: 0
    implicitHeight: content.implicitHeight

    states: State {
        name: "visible"
        when: root.visibilities.osd && Config.osd.enabled

        PropertyChanges {
            root.implicitWidth: content.implicitWidth
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitWidth"
                easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitWidth"
                easing.bezierCurve: Config.appearance.anim.curves.emphasized
            }
        }
    ]

    Content {
        id: content

        monitor: Brightness.getMonitorForScreen(root.screen)
        visibilities: root.visibilities
    }
}
