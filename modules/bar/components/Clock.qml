pragma ComponentBehavior: Bound

import qs.components
import qs.services
import "../../../config"
import QtQuick

Column {
    id: root

    property color colour: Colours.palette.m3tertiary

    spacing: Config.appearance.spacing.small

    Loader {
        anchors.horizontalCenter: parent.horizontalCenter

        active: Config.bar.clock.showIcon
        visible: active
        asynchronous: true

        sourceComponent: MaterialIcon {
            text: "calendar_month"
            color: root.colour
        }
    }

    StyledText {
        id: text

        anchors.horizontalCenter: parent.horizontalCenter

        horizontalAlignment: StyledText.AlignHCenter
        text: Time.format(Config.services.useTwelveHourClock ? "hh\nmm\nA" : "hh\nmm")
        font.pointSize: Config.appearance.font.size.smaller
        font.family: Config.appearance.font.family.mono
        color: root.colour
    }
}
