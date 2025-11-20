import ".."
import "../effects"
import qs.services
import "../../config"
import QtQuick

StyledRect {
    required property int extra

    anchors.right: parent.right
    anchors.margins: Config.appearance.padding.normal

    color: Colours.palette.m3tertiary
    radius: Config.appearance.rounding.small

    implicitWidth: count.implicitWidth + Config.appearance.padding.normal * 2
    implicitHeight: count.implicitHeight + Config.appearance.padding.small * 2

    opacity: extra > 0 ? 1 : 0
    scale: extra > 0 ? 1 : 0.5

    Elevation {
        anchors.fill: parent
        radius: parent.radius
        opacity: parent.opacity
        z: -1
        level: 2
    }

    StyledText {
        id: count

        anchors.centerIn: parent
        animate: parent.opacity > 0
        text: qsTr("+%1").arg(parent.extra)
        color: Colours.palette.m3onTertiary
    }

    Behavior on opacity {
        Anim {
            duration: Config.appearance.anim.durations.expressiveFastSpatial
        }
    }

    Behavior on scale {
        Anim {
            duration: Config.appearance.anim.durations.expressiveFastSpatial
            easing.bezierCurve: Config.appearance.anim.curves.expressiveFastSpatial
        }
    }
}
