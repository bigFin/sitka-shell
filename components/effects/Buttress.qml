import QtQuick
import QtQuick.Shapes
import qs.config
import qs.services

Shape {
    id: root

    // Orientation: Which corner of the PARENT is this buttress attached to?
    // 0: Top-Left (Left of parent, Top aligned)
    // 1: Top-Right (Right of parent, Top aligned)
    // 2: Bottom-Left (Left of parent, Bottom aligned)
    // 3: Bottom-Right (Right of parent, Bottom aligned)
    property int orientation: 0
    
    // Size is used by parent to determine max width, but here we just render to 'width'
    property real size: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6
    property color color: Colours.palette.m3surface
    
    // Geometry
    // width is set by parent animation
    height: size
    
    // Optimizations
    layer.enabled: true
    layer.samples: 4
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.color

        // Start Point
        startX: (root.orientation === 0 || root.orientation === 2) ? root.width : 0
        startY: 0

        // Line 1
        PathLine {
            x: (root.orientation === 0) ? 0 : (root.orientation === 1) ? root.width : 0
            y: (root.orientation === 0 || root.orientation === 1) ? 0 : root.height
        }

        // Line 2
        PathLine {
            x: (root.orientation === 1) ? 0 : root.width
            y: root.height
        }
        
        // Auto Close to Start
    }
}
