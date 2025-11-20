import qs.components
import qs.services
import "../../../config"
import Quickshell
import QtQuick

StyledRect {
    id: root

    implicitWidth: implicitHeight
    implicitHeight: icon.implicitHeight + Config.appearance.padding.small * 2

    radius: Config.appearance.rounding.full
    color: Qt.alpha(Colours.palette.m3primaryContainer, IdleInhibitor.enabled ? 1 : 0)

    StateLayer {
        function onClicked(): void {
            IdleInhibitor.enabled = !IdleInhibitor.enabled;
        }
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -1

        text: "coffee"
        color: IdleInhibitor.enabled ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3secondary
        font.bold: true
        font.pointSize: Config.appearance.font.size.normal
    }
}
