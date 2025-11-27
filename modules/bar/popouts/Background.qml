import qs.components
import qs.services
import "../../../config"
import qs.components.effects // For Buttress
import QtQuick

Item {
    id: root

    required property Wrapper wrapper
    required property bool invertBottomRounding // Ignored for chamfers

    property alias color: mainRect.color

    width: wrapper.width
    height: wrapper.height
    visible: height > 0

    StyledRect {
        id: mainRect
        anchors.fill: parent

        color: Colours.palette.m3surface
        filletSize: Config.appearance.fillet.large
        
        readonly property bool attached: !wrapper.isDetached
        
        // If detached, round all. If attached (to left bar), round right side.
        topLeftFillet: false
        topRightFillet: true
        bottomLeftFillet: false
        bottomRightFillet: true
    }

    // Top-left Buttress
    Buttress {
        id: topLeftButtress
        orientation: 0 // Top-Left
        size: mainRect.filletSize
        color: mainRect.color
        anchors.right: parent.left
        anchors.top: parent.top
        width: wrapper.buttressSize
    }

    // Bottom-left Buttress
    Buttress {
        id: bottomLeftButtress
        orientation: 2 // Bottom-Left
        size: mainRect.filletSize
        color: mainRect.color
        anchors.right: parent.left
        anchors.bottom: parent.bottom
        width: wrapper.buttressSize
    }
}