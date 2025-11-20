import qs.services
import "../../config"
import QtQuick
import ".."

StyledRect {
    id: root
    property color basecolor: Colours.palette.m3secondaryContainer
    color: disabled ? Colours.palette.m3surfaceContainerLow : basecolor
    property color onColor: Colours.palette.m3onSurface
    property alias disabled: stateLayer.disabled
    property alias icon: icon.text

    property real implicitSize: Config.appearance.font.size.normal

    function onClicked(): void {
    }

    radius: Config.appearance.rounding.normal
    implicitWidth: root.implicitSize
    implicitHeight: root.implicitSize

    MaterialIcon {
        id: icon
        color: parent.onColor
        font.pointSize: Config.appearance.font.size.small
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        opacity: icon.text && stateLayer.containsMouse ? 1 : 0
        Behavior on opacity {
            Anim {}
        }
    }

    StateLayer {
        id: stateLayer
        color: parent.onColor
        function onClicked(): void {
            parent.onClicked();
        }
    }
}
