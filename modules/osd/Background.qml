import qs.components
import qs.services
import "../../config"
import qs.components.effects
import QtQuick

Item {
    id: root

    required property Wrapper wrapper
    
    width: wrapper.width
    height: wrapper.height
    visible: height > 0 && wrapper.buttressSize > 0.5

    property alias color: mainRect.color

    StyledRect {
        id: mainRect
        anchors.fill: parent
        
        color: Colours.palette.m3surface
        
        // Apply large fillets for main containers
        filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6
        
        // Enable left fillets only
        topLeftFillet: true
        topRightFillet: false
        bottomLeftFillet: true
        bottomRightFillet: false
        fillDisabledFillets: true
    }

    // Top Buttress (Right Edge): Sits above, aligned right.
    // Orientation 2: Straight Right & Bottom edges.
    Buttress {
        id: topButtress
        orientation: 2
        size: mainRect.filletSize
        color: mainRect.color
        anchors.right: parent.right
        anchors.bottom: parent.top
        width: root.wrapper.buttressSize
    }

    // Bottom Buttress (Right Edge): Sits below, aligned right.
    // Orientation 0: Straight Right & Top edges.
    Buttress {
        id: bottomButtress
        orientation: 0
        size: mainRect.filletSize
        color: mainRect.color
        anchors.right: parent.right
        anchors.top: parent.bottom
        width: root.wrapper.buttressSize
    }
}