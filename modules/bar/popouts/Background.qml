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
    visible: height > 0 && wrapper.buttressSize > 0.5

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
        orientation: 3 // Top-Left location (Above), use L shape (Bottom-Left filled)
        size: mainRect.filletSize
        color: mainRect.color
        anchors.left: parent.left
        anchors.bottom: parent.top
        width: wrapper.buttressSize
    }

    // Bottom-left Buttress
    Buttress {
        id: bottomLeftButtress
        orientation: 1 // Bottom-Left location (Below), use F shape (Top-Left filled)
        size: mainRect.filletSize
        color: mainRect.color
        anchors.left: parent.left
        anchors.top: parent.bottom
        width: wrapper.buttressSize
    }
}