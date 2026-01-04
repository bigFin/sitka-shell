import qs.components
import qs.services
import "../../../config"
import Quickshell
import QtQuick

StyledRect {
    id: root

    required property PersistentProperties visibilities

    implicitWidth: implicitHeight
    implicitHeight: icon.implicitHeight + Config.appearance.padding.small * 2
    radius: Config.appearance.rounding.full
    color: visibilities.utilities ? Colours.palette.m3primaryContainer : "transparent"

    MaterialIcon {
        id: icon
        anchors.centerIn: parent
        text: "tune"
        color: visibilities.utilities
            ? Colours.palette.m3onPrimaryContainer
            : Colours.palette.m3onSurface
        font.pointSize: Config.appearance.font.size.normal
    }

    StateLayer {
        radius: parent.radius
        function onClicked(): void {
            root.visibilities.utilities = !root.visibilities.utilities
        }
    }
}
