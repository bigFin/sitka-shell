import QtQuick
import "effects"
import "../config"

Item {
    id: root
    
    property color color: "transparent"
    readonly property real effectiveFilletSize: Math.max(
        0,
        Math.min(filletSize, width / 2, height / 2)
    )
    
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
    property bool fillDisabledFillets: true
    
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
            y: root.effectiveFilletSize
            width: root.width
            height: Math.max(0, root.height - (root.effectiveFilletSize * 2))
            color: root.color
        }
        
        Rectangle {
            // Vertical bar (excludes corners)
            x: root.effectiveFilletSize
            y: 0
            width: Math.max(0, root.width - (root.effectiveFilletSize * 2))
            height: root.height
            color: root.color
        }
        
        // Corners
        CornerPiece {
            width: root.effectiveFilletSize
            height: root.effectiveFilletSize
            color: root.color
            filletStyle: root.topLeftFilletStyle
            filletSize: root.effectiveFilletSize
            orientation: 0 // TOP_LEFT
            anchors.top: parent.top
            anchors.left: parent.left
            visible: root.topLeftFillet && root.effectiveFilletSize > 0
        }
        
        CornerPiece {
            width: root.effectiveFilletSize
            height: root.effectiveFilletSize
            color: root.color
            filletStyle: root.topRightFilletStyle
            filletSize: root.effectiveFilletSize
            orientation: 1 // TOP_RIGHT
            anchors.top: parent.top
            anchors.right: parent.right
            visible: root.topRightFillet && root.effectiveFilletSize > 0
        }
        
        CornerPiece {
            width: root.effectiveFilletSize
            height: root.effectiveFilletSize
            color: root.color
            filletStyle: root.bottomLeftFilletStyle
            filletSize: root.effectiveFilletSize
            orientation: 2 // BOTTOM_LEFT
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            visible: root.bottomLeftFillet && root.effectiveFilletSize > 0
        }
        
        CornerPiece {
            width: root.effectiveFilletSize
            height: root.effectiveFilletSize
            color: root.color
            filletStyle: root.bottomRightFilletStyle
            filletSize: root.effectiveFilletSize
            orientation: 3 // BOTTOM_RIGHT
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            visible: root.bottomRightFillet && root.effectiveFilletSize > 0
        }
        
        // Fill gaps for disabled fillets
        Rectangle {
            visible: !root.topLeftFillet && root.fillDisabledFillets
            width: root.effectiveFilletSize
            height: root.effectiveFilletSize
            color: root.color
            anchors.top: parent.top
            anchors.left: parent.left
        }
        
        Rectangle {
            visible: !root.topRightFillet && root.fillDisabledFillets
            width: root.effectiveFilletSize
            height: root.effectiveFilletSize
            color: root.color
            anchors.top: parent.top
            anchors.right: parent.right
        }
        
        Rectangle {
            visible: !root.bottomLeftFillet && root.fillDisabledFillets
            width: root.effectiveFilletSize
            height: root.effectiveFilletSize
            color: root.color
            anchors.bottom: parent.bottom
            anchors.left: parent.left
        }
        
        Rectangle {
            visible: !root.bottomRightFillet && root.fillDisabledFillets
            width: root.effectiveFilletSize
            height: root.effectiveFilletSize
            color: root.color
            anchors.bottom: parent.bottom
            anchors.right: parent.right
        }
    }
}
