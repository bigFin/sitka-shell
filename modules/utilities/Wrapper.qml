import qs.components
import "../../config"
import QtQuick

Item {
    id: root

    required property bool visibility

    visible: height > 0
    implicitHeight: 0
    implicitWidth: content.implicitWidth

    states: State {
        name: "visible"
        when: root.visibility

        PropertyChanges {
            root.implicitHeight: content.implicitHeight
        }
    }

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
        }
    ]

    Content {
        id: content
    }
}
