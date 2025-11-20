import qs.components
import qs.services
import "../../config"
import QtQuick

Item {
    implicitWidth: timeText.implicitWidth + Config.appearance.padding.large * 2
    implicitHeight: timeText.implicitHeight + Config.appearance.padding.large * 2

    StyledText {
        id: timeText

        anchors.centerIn: parent
        text: Time.format(Config.services.useTwelveHourClock ? "hh:mm:ss A" : "hh:mm:ss")
        font.pointSize: Config.appearance.font.size.extraLarge
        font.bold: true
    }
}
