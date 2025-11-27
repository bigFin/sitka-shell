import QtQuick
import qs.config
import qs.services
import qs.components // For Anim

Canvas {
    id: root

    // Orientation: Which corner of the PARENT is this buttress attached to?
    // 0: Top-Left (Draws on Left side, Top aligned)
    // 1: Top-Right (Draws on Right side, Top aligned)
    // 2: Bottom-Left (Draws on Left side, Bottom aligned)
    // 3: Bottom-Right (Draws on Right side, Bottom aligned)
    property int orientation: 0
    
    // Size of the buttress (usually matches fillet size)
    property real size: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6
    
    // Color
    property color color: Colours.palette.m3surface
    
    // Active state for animation
    property bool active: true
    
    // Animation duration
    property int animDuration: Config.appearance && Config.appearance.anim ? Config.appearance.anim.durations.normal : 200
    
    // Geometry
    width: active ? size : 0
    height: size
    visible: width > 0

    Behavior on width {
        Anim {
            duration: root.animDuration
            easing.bezierCurve: Config.appearance.anim.curves.emphasized
        }
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.fillStyle = root.color;
        ctx.beginPath();
        
        if (orientation === 0) { // Top-Left (Left of parent)
            // Triangle: Top-Right (w,0), Top-Left (0,0), Bottom-Right (w,h)
            ctx.moveTo(width, 0);
            ctx.lineTo(0, 0);
            ctx.lineTo(width, height);
        } else if (orientation === 1) { // Top-Right (Right of parent)
            // Triangle: Top-Left (0,0), Top-Right (w,0), Bottom-Left (0,h)
            ctx.moveTo(0, 0);
            ctx.lineTo(width, 0);
            ctx.lineTo(0, height);
        } else if (orientation === 2) { // Bottom-Left (Left of parent)
            // Triangle: Top-Right (w,0), Bottom-Left (0,h), Bottom-Right (w,h)
            ctx.moveTo(width, 0);
            ctx.lineTo(0, height);
            ctx.lineTo(width, height);
        } else if (orientation === 3) { // Bottom-Right (Right of parent)
            // Triangle: Top-Left (0,0), Bottom-Left (0,h), Bottom-Right (w,h)
            ctx.moveTo(0, 0);
            ctx.lineTo(0, height);
            ctx.lineTo(width, height);
        }
        
        ctx.closePath();
        ctx.fill();
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onColorChanged: requestPaint()
    onOrientationChanged: requestPaint()
    
    Component.onCompleted: requestPaint()
}
