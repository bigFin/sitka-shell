pragma ComponentBehavior: Bound

import qs.components
import qs.services
import "../../../config"
import QtQuick

Column {
    id: root

    property color colour: Colours.themeName === "Observatory" ? Colours.palette.m3primary : Colours.palette.m3tertiary

    spacing: Config.appearance.spacing.small

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: text.implicitWidth
        height: 1
        visible: Colours.themeName === "Observatory"
        color: Colours.palette.m3outline
    }

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
