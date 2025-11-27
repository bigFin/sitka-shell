import qs.components
import qs.services
import "../../config"
import qs.components.effects // For Buttress
import QtQuick

Item {
    id: root

    required property Wrapper wrapper
    
    // Proxy properties for animation/layout
    property alias color: mainRect.color
    
    // Match wrapper dimensions explicitly
    width: wrapper.width
    height: wrapper.height
    // Ensure we hide completely when collapsed to avoid "Square Artifacts" from the un-filleted corners
    visible: height > 0 && wrapper.buttressSize > 0.5

    // Main Background Rectangle
    StyledRect {
        id: mainRect
        anchors.fill: parent
        
        // Match the original background properties
        color: Colours.palette.m3surface
        
        // Apply large fillets for main containers
        filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6
        
        // Top corners: Square (to attach buttresses)
        topLeftFillet: false
        topRightFillet: false
        
        // Bottom corners: Chamfer (Subtractive)
        bottomLeftFillet: true
        bottomRightFillet: true
        bottomLeftFilletStyle: 1
        bottomRightFilletStyle: 1
    }
    
    // Left Buttress (Additive)
    Buttress {
        id: leftButtress
        orientation: 0 // Top-Left
        size: mainRect.filletSize
        color: mainRect.color
        anchors.right: parent.left
        anchors.top: parent.top
        width: root.wrapper.buttressSize
    }
    
    // Right Buttress (Additive)
    Buttress {
        id: rightButtress
        orientation: 1 // Top-Right
        size: mainRect.filletSize
        color: mainRect.color
        anchors.left: parent.right
        anchors.top: parent.top
        width: root.wrapper.buttressSize
    }
}