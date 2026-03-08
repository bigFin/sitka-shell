import qs.components
import qs.services
import "../../config"
import qs.components.effects // For Buttress
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

    // Main Background Rectangle
    StyledRect {
        id: mainRect
        anchors.fill: parent
        
        // Match the original background properties
        color: Colours.palette.m3surface
        
        // Apply large fillets for main containers
        filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6
        
        // Keep top corners filleted whenever buttresses are not fully present.
        // This prevents tiny square flash artifacts during collapse transitions.
        topLeftFillet: !root.buttressesVisible
        topRightFillet: !root.buttressesVisible
        topLeftFilletStyle: 1
        topRightFilletStyle: 1
        
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
