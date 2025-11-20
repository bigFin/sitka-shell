import "../../config"
import QtQuick

Item {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right

    // implicitWidth: 300
    // implicitHeight: 100

    // Rectangle {
    //     anchors.fill: parent
    // }

    Behavior on implicitHeight {
        Anim {}
    }

    component Anim: NumberAnimation {
        duration: Config.appearance.anim.durations.expressiveDefaultSpatial
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
    }
}
