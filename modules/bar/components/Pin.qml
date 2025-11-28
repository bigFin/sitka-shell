import qs.components
import qs.services
import "../../../config"
import Quickshell
import QtQuick

Item {
    id: root

    implicitWidth: icon.implicitHeight + Config.appearance.padding.small * 2
    implicitHeight: icon.implicitHeight

    StateLayer {
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Config.appearance.padding.small * 2

        radius: Config.appearance.rounding.full

        function onClicked(): void {
            Config.bar.persistent = !Config.bar.persistent;
        }
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: "push_pin"
        rotation: Config.bar.persistent ? 0 : 45

        color: Config.bar.persistent ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        font.pointSize: Config.appearance.font.size.normal
        
        Behavior on rotation {
            NumberAnimation {
                duration: Config.appearance.anim.durations.small
                easing.bezierCurve: Config.appearance.anim.curves.standard
            }
        }
        
        Behavior on color {
            ColorAnimation {
                duration: Config.appearance.anim.durations.small
                easing.bezierCurve: Config.appearance.anim.curves.standard
            }
        }
    }
}
