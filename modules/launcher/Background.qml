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
    
    // Left Buttress (Additive)
    Canvas {
        id: leftButtress
        width: mainRect.filletSize
        height: mainRect.filletSize
        anchors.right: parent.left
        anchors.bottom: parent.bottom
        visible: root.wrapper.visibilities.launcher && width > 0
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = mainRect.color;
            ctx.beginPath();
            ctx.moveTo(0, 0); // top-left of canvas
            ctx.lineTo(0, height); // bottom-left
            ctx.lineTo(width, height); // bottom-right
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
        width: mainRect.filletSize
        height: mainRect.filletSize
        anchors.left: parent.right
        anchors.bottom: parent.bottom
        visible: root.wrapper.visibilities.launcher && width > 0
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = mainRect.color;
            ctx.beginPath();
            ctx.moveTo(width, 0); // top-right
            ctx.lineTo(width, height); // bottom-right
            ctx.lineTo(0, height); // bottom-left
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