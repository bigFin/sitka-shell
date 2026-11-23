import qs.components.effects
import QtQuick

Item {
    id: root

    required property Wrapper wrapper
    
    // Proxy properties for animation/layout
    property alias color: mainRect.color
    
    // Match wrapper dimensions explicitly
    width: wrapper.width
    height: wrapper.height
    visible: height > 0 && wrapper.buttressSize > 0.5 // Hide completely when collapsed to prevent artifacts

    DrawerPlate {
        id: mainRect
        anchors.fill: parent

        dockAtTop: false
    }
    
    // Bottom-left Buttress
    Buttress {
        id: bottomLeftButtress
        orientation: 2 // Bottom-Left
        size: mainRect.filletSize
        color: mainRect.color
        anchors.right: parent.left
        anchors.bottom: parent.bottom
        width: root.wrapper.buttressSize
    }
    
    // Bottom-right Buttress
    Buttress {
        id: bottomRightButtress
        orientation: 3 // Bottom-Right
        size: mainRect.filletSize
        color: mainRect.color
        anchors.left: parent.right
        anchors.bottom: parent.bottom
        width: root.wrapper.buttressSize
    }
}
