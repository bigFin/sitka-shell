import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    anchors.fill: parent
    spacing: Appearance.spacing.large

    MaterialIcon {
        animate: true
        text: Weather.icon || "cloud_alert"
        color: Colours.palette.m3secondary
        font.pointSize: Appearance.font.size.extraLarge * 2.5
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignVCenter

        spacing: Appearance.spacing.small

        StyledText {
            Layout.fillWidth: true

            animate: true
            text: Config.services.useFahrenheit ? Weather.tempF : Weather.tempC
            color: Colours.palette.m3primary
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: Appearance.font.size.extraLarge
            font.weight: 500
        }

        StyledText {
            Layout.fillWidth: true

            animate: true
            text: Weather.description || qsTr("No weather")
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: Appearance.font.size.large
            elide: Text.ElideRight
        }
    }

    Timer {
        running: true
        triggeredOnStart: true
        repeat: true
        interval: 900000 // 15 minutes
        onTriggered: Weather.reload()
    }
}
