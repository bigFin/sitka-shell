import qs.components
import qs.services
import "../../../config"
import "../../../utils/scripts/dashboardData.js" as DashboardData
import QtQuick
import QtQuick.Layouts

Item {
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Math.max(Config.dashboard.sizes.dateTimeWidth, utcLabel.visible ? utcLabel.implicitWidth + Config.appearance.padding.normal * 2 : 0)

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Config.appearance.spacing.small

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Local time")
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.format(Config.services.useTwelveHourClock ? "hh:mm AP" : "hh:mm").split(" ")[0]
            color: Colours.palette.m3secondary
            font.pointSize: Config.appearance.font.size.large
            font.family: Config.appearance.font.family.clock
            font.weight: 600
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            visible: Config.services.useTwelveHourClock
            text: Time.format("AP")
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            id: utcLabel
            visible: Config.dashboard.showUtc
            text: DashboardData.utc(Time.date, Config.services.useTwelveHourClock)
            font.family: Config.appearance.font.family.clock
        }
    }
}
