import qs.components
import qs.services
import "../../../config"
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
        font.pointSize: Config.appearance.font.size.extraLarge * 1.5
    }

    Column {
        id: info

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: icon.right
        anchors.leftMargin: Config.appearance.spacing.small

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
            text: Weather.available ? Weather.description : qsTr("Weather unavailable")

            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.parent.width - icon.implicitWidth - info.anchors.leftMargin - Config.appearance.padding.large * 2)
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Weather.stale ? (Weather.loading ? qsTr("Stale • updating…") : qsTr("Stale • refresh failed")) : Weather.loading ? qsTr("Updating…")
                : Weather.lastUpdate !== null ? qsTr("Updated %1").arg(Qt.formatTime(new Date(Weather.lastUpdate), "hh:mm")) : qsTr("No reading yet")
            color: Weather.stale ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.parent.width - icon.implicitWidth - info.anchors.leftMargin - Config.appearance.padding.large * 2)
        }
    }
}
