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
    visible: height > 0 // Hide completely when collapsed to prevent artifacts

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
        active: root.wrapper.visibilities.dashboard || root.wrapper.expanded
    }
    
    // Right Buttress (Additive)
    Buttress {
        id: rightButtress
        orientation: 1 // Top-Right
        size: mainRect.filletSize
        color: mainRect.color
        anchors.left: parent.right
        anchors.top: parent.top
        active: root.wrapper.visibilities.dashboard || root.wrapper.expanded
    }
}