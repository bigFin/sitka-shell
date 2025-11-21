import qs.components
import qs.services
import "../../config"
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
    Canvas {
        id: leftButtress
        width: (root.wrapper.visibilities.dashboard || root.wrapper.expanded) ? mainRect.filletSize : 0
        height: mainRect.filletSize
        anchors.right: parent.left
        anchors.top: parent.top
        visible: width > 0
        
        Behavior on width { Anim {} }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = mainRect.color;
            ctx.beginPath();
            ctx.moveTo(width, 0);
            ctx.lineTo(0, 0);
            ctx.lineTo(width, height);
            ctx.closePath();
            ctx.fill();
        }
        
        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: mainRect
            function onColorChanged() { leftButtress.requestPaint(); }
        }
    }
    
    // Right Buttress (Additive)
    Canvas {
        id: rightButtress
        width: (root.wrapper.visibilities.dashboard || root.wrapper.expanded) ? mainRect.filletSize : 0
        height: mainRect.filletSize
        anchors.left: parent.right
        anchors.top: parent.top
        visible: width > 0

        Behavior on width { Anim {} }
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = mainRect.color;
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(width, 0);
            ctx.lineTo(0, height);
            ctx.closePath();
            ctx.fill();
        }
        
        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: mainRect
            function onColorChanged() { rightButtress.requestPaint(); }
        }
    }
}