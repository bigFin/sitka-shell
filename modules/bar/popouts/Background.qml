import qs.components
import qs.services
import "../../../config"
import QtQuick

Item {
    id: root

    required property Wrapper wrapper
    required property bool invertBottomRounding // Ignored for chamfers

    property alias color: mainRect.color

    width: wrapper.width
    height: wrapper.height
    visible: height > 0

    StyledRect {
        id: mainRect
        anchors.fill: parent

        color: Colours.palette.m3surface
        filletSize: Config.appearance.fillet.large
        
        readonly property bool attached: !wrapper.isDetached
        
        // If detached, round all. If attached (to left bar), round right side.
        topLeftFillet: false
        topRightFillet: true
        bottomLeftFillet: false
        bottomRightFillet: true
    }

    // Top-left Buttress
    Canvas {
        id: topLeftButtress
        width: mainRect.filletSize
        height: mainRect.filletSize
        anchors.right: parent.left
        anchors.top: parent.top
        visible: mainRect.attached && width > 0

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = mainRect.color;
            ctx.beginPath();
            ctx.moveTo(width, 0); // top-right of canvas
            ctx.lineTo(0, 0);     // top-left
            ctx.lineTo(width, height); // bottom-right
            ctx.closePath();
            ctx.fill();
        }
        
        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: mainRect
            function onColorChanged() { topLeftButtress.requestPaint(); }
        }
    }

    // Bottom-left Buttress
    Canvas {
        id: bottomLeftButtress
        width: mainRect.filletSize
        height: mainRect.filletSize
        anchors.right: parent.left
        anchors.bottom: parent.bottom
        visible: mainRect.attached && width > 0

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = mainRect.color;
            ctx.beginPath();
            ctx.moveTo(width, 0);     // top-right of canvas
            ctx.lineTo(0, height);    // bottom-left
            ctx.lineTo(width, height); // bottom-right
            ctx.closePath();
            ctx.fill();
        }
        
        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: mainRect
            function onColorChanged() { bottomLeftButtress.requestPaint(); }
        }
    }
}