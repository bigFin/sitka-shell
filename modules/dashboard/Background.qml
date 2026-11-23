import qs.components.effects
import QtQuick

Item {
    id: root

    required property Wrapper wrapper
    readonly property real buttressMinVisible: mainRect.filletSize - 0.5
    readonly property bool buttressesVisible: wrapper.buttressSize >= buttressMinVisible
    
    // Proxy properties for animation/layout
    property alias color: mainRect.color
    
    // Match wrapper dimensions explicitly
    width: wrapper.width
    height: wrapper.height
    visible: height > 0

    DrawerPlate {
        id: mainRect
        anchors.fill: parent

        dockAtTop: true
        // Keep top corners filleted whenever buttresses are not fully present.
        topButtressesVisible: root.buttressesVisible
    }
    
    // Left Buttress (Additive)
    Buttress {
        id: leftButtress
        orientation: 0 // Top-Left
        size: mainRect.filletSize
        color: mainRect.color
        anchors.right: parent.left
        anchors.top: parent.top
        visible: root.buttressesVisible
        width: root.buttressesVisible ? mainRect.filletSize : 0
    }
    
    // Right Buttress (Additive)
    Buttress {
        id: rightButtress
        orientation: 1 // Top-Right
        size: mainRect.filletSize
        color: mainRect.color
        anchors.left: parent.right
        anchors.top: parent.top
        visible: root.buttressesVisible
        width: root.buttressesVisible ? mainRect.filletSize : 0
    }
}
