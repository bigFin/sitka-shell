import qs.components
import qs.services
import "../../config"
import QtQuick
import QtQuick.Controls

RadioButton {
    id: root

    font.pointSize: Config.appearance.font.size.smaller

    indicator: Rectangle {
        id: outerCircle

        implicitWidth: 20
        implicitHeight: 20
        radius: Config.appearance.rounding.full
        color: "transparent"
        border.color: root.checked ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        border.width: 2
        anchors.verticalCenter: parent.verticalCenter

        StateLayer {
            anchors.margins: -Config.appearance.padding.smaller
            color: root.checked ? Colours.palette.m3onSurface : Colours.palette.m3primary
            z: -1

            function onClicked(): void {
                root.click();
            }
        }

        StyledRect {
            anchors.centerIn: parent
            implicitWidth: 8
            implicitHeight: 8

            radius: Config.appearance.rounding.full
            color: root.checked ? Colours.palette.m3primary : "transparent"
        }

        Behavior on border.color {
            CAnim {}
        }
    }

    contentItem: StyledText {
        text: root.text
        font.pointSize: root.font.pointSize
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: outerCircle.right
        anchors.leftMargin: Config.appearance.spacing.smaller
    }
}
