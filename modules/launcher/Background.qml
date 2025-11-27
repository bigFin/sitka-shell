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
        color: Qt.rgba(Colours.palette.m3surface.r, Colours.palette.m3surface.g, Colours.palette.m3surface.b, 1)
        
        // Apply large fillets for main containers
        filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6
        
        // Top corners: Chamfer
        topLeftFillet: true
        topRightFillet: true
        topLeftFilletStyle: 1
        topRightFilletStyle: 1
        
        // Bottom corners: Square (to attach buttresses)
        bottomLeftFillet: false
        bottomRightFillet: false
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