import QtQuick
import "effects"
import "../config"

Item {
    id: root
    
    property color color: "transparent"
    
    // Fillet/chamfer support
    property bool enableFillets: Config.appearance ? Config.appearance.enableFilletEffects : true
    property int filletStyle: Config.appearance ? Config.appearance.filletStyle : 0
    property int filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.normal : 4
    property bool topLeftFillet: true
    property bool topRightFillet: true
    property bool bottomLeftFillet: true
    property bool bottomRightFillet: true
    property int topLeftFilletStyle: filletStyle
    property int topRightFilletStyle: filletStyle
    property int bottomLeftFilletStyle: filletStyle
    property int bottomRightFilletStyle: filletStyle
    
    // Radius support (fallback if fillets disabled)
    property int radius: 0
    property alias topLeftRadius: fallbackRect.topLeftRadius
    property alias topRightRadius: fallbackRect.topRightRadius
    property alias bottomLeftRadius: fallbackRect.bottomLeftRadius
    property alias bottomRightRadius: fallbackRect.bottomRightRadius
    
    // Border support (aliased to fallback rect for compatibility)
    property alias border: fallbackRect.border

    // Animation support
    Behavior on color {
        CAnim {}
    }
    
    // Standard rounded rectangle (fallback)
    Rectangle {
        id: fallbackRect
        anchors.fill: parent
        color: root.color
        radius: root.radius
        visible: !root.enableFillets || root.filletStyle < 0
    }
    
    // Fillet implementation using composed shapes
    Item {
        anchors.fill: parent
        visible: root.enableFillets && root.filletStyle >= 0
        
        // Center cross (vertical and horizontal bars)
        Rectangle {
            // Horizontal bar (excludes corners)
            x: 0
            y: root.filletSize
            width: root.width
            height: root.height - (root.filletSize * 2)
            color: root.color
        }
        
        Rectangle {
            // Vertical bar (excludes corners)
            x: root.filletSize
            y: 0
            width: root.width - (root.filletSize * 2)
            height: root.height
            color: root.color
        }
        
        // Corners
        CornerPiece {
            width: root.filletSize
            height: root.filletSize
            color: root.color
            filletStyle: root.topLeftFilletStyle
            filletSize: root.filletSize
            orientation: 0 // TOP_LEFT
            anchors.top: parent.top
            anchors.left: parent.left
            visible: root.topLeftFillet
        }
        
        CornerPiece {
            width: root.filletSize
            height: root.filletSize
            color: root.color
            filletStyle: root.topRightFilletStyle
            filletSize: root.filletSize
            orientation: 1 // TOP_RIGHT
            anchors.top: parent.top
            anchors.right: parent.right
            visible: root.topRightFillet
        }
        
        CornerPiece {
            width: root.filletSize
            height: root.filletSize
            color: root.color
            filletStyle: root.bottomLeftFilletStyle
            filletSize: root.filletSize
            orientation: 2 // BOTTOM_LEFT
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            visible: root.bottomLeftFillet
        }
        
        CornerPiece {
            width: root.filletSize
            height: root.filletSize
            color: root.color
            filletStyle: root.bottomRightFilletStyle
            filletSize: root.filletSize
            orientation: 3 // BOTTOM_RIGHT
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            visible: root.bottomRightFillet
        }
        
        // Fill gaps for disabled fillets
        Rectangle {
            visible: !root.topLeftFillet
            width: root.filletSize
            height: root.filletSize
            color: root.color
            anchors.top: parent.top
            anchors.left: parent.left
        }
        
        Rectangle {
            visible: !root.topRightFillet
            width: root.filletSize
            height: root.filletSize
            color: root.color
            anchors.top: parent.top
            anchors.right: parent.right
        }
        
        Rectangle {
            visible: !root.bottomLeftFillet
            width: root.filletSize
            height: root.filletSize
            color: root.color
            anchors.bottom: parent.bottom
            anchors.left: parent.left
        }
        
        Rectangle {
            visible: !root.bottomRightFillet
            width: root.filletSize
            height: root.filletSize
            color: root.color
            anchors.bottom: parent.bottom
            anchors.right: parent.right
        }
    }
}