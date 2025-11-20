import qs.components
import qs.services
import "../../../config"
import qs.utils
import QtQuick

Item {
    id: root

    anchors.centerIn: parent

    implicitWidth: icon.implicitWidth + info.implicitWidth + info.anchors.leftMargin

    Component.onCompleted: Weather.reload()

    MaterialIcon {
        id: icon

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        animate: true
        text: Weather.icon
        color: Colours.palette.m3secondary
        font.pointSize: Config.appearance.font.size.extraLarge * 2
    }

    Column {
        id: info

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: icon.right
        anchors.leftMargin: Config.appearance.spacing.large

        spacing: Config.appearance.spacing.small

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter

            animate: true
            text: Weather.temp
            color: Colours.palette.m3primary
            font.pointSize: Config.appearance.font.size.extraLarge
            font.weight: 500
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter

            animate: true
            text: Weather.description

            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.parent.width - icon.implicitWidth - info.anchors.leftMargin - Config.appearance.padding.large * 2)
        }
    }
}
