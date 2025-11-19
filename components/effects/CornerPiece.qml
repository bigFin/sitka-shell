import QtQuick

Item {
    id: cornerShape
    width: 48
    height: 48

    property color color: "red"
    property int radius: 0
    property int orientation: 0 // 0=TOP_LEFT, 1=TOP_RIGHT, 2=BOTTOM_LEFT, 3=BOTTOM_RIGHT
    property bool invertH: false
    property bool invertV: false
    
    // Fillet/chamfer support
    property int filletStyle: 0 // 0=radius, 1=chamfer, 2=fillet
    property int filletSize: 4

    onRadiusChanged: cornerCanvas.requestPaint()
    onColorChanged: cornerCanvas.requestPaint()
    onFilletStyleChanged: cornerCanvas.requestPaint()
    onFilletSizeChanged: cornerCanvas.requestPaint()

    Canvas {
        id: cornerCanvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            const w = parent.width;
            const h = parent.height;
            
            ctx.reset();
            ctx.save();

            ctx.translate(cornerShape.invertH ? w : 0, cornerShape.invertV ? h : 0);
            ctx.scale(cornerShape.invertH ? -1 : 1, cornerShape.invertV ? -1 : 1);

            // draw full rect
            ctx.beginPath();
            ctx.rect(0, 0, w, h);
            ctx.closePath();

            // draw corner cutout based on style
            ctx.beginPath();

            if (cornerShape.filletStyle === 1) {
                // Chamfer style
                const c = Math.max(0, Math.min(cornerShape.filletSize, Math.min(w, h) / 2));
                
                switch (cornerShape.orientation) {
                case 0: // TOP_LEFT
                    ctx.moveTo(0, c);
                    ctx.lineTo(0, 0);
                    ctx.lineTo(c, 0);
                    ctx.lineTo(0, c);
                    break;
                case 1: // TOP_RIGHT
                    ctx.moveTo(w - c, 0);
                    ctx.lineTo(w, 0);
                    ctx.lineTo(w, c);
                    ctx.lineTo(w - c, 0);
                    break;
                case 2: // BOTTOM_LEFT
                    ctx.moveTo(0, h - c);
                    ctx.lineTo(0, h);
                    ctx.lineTo(c, h);
                    ctx.lineTo(0, h - c);
                    break;
                case 3: // BOTTOM_RIGHT
                    ctx.moveTo(w - c, h);
                    ctx.lineTo(w, h);
                    ctx.lineTo(w, h - c);
                    ctx.lineTo(w - c, h);
                    break;
                }
            } else if (cornerShape.filletStyle === 2) {
                // Fillet style
                const r = Math.max(0, Math.min(cornerShape.filletSize, Math.min(w, h) / 2));
                
                switch (cornerShape.orientation) {
                case 0: // TOP_LEFT
                    ctx.moveTo(0, r);
                    ctx.lineTo(0, 0);
                    ctx.lineTo(r, 0);
                    ctx.quadraticCurveTo(0, 0, 0, r);
                    break;
                case 1: // TOP_RIGHT
                    ctx.moveTo(w - r, 0);
                    ctx.lineTo(w, 0);
                    ctx.lineTo(w, r);
                    ctx.quadraticCurveTo(w, 0, w - r, 0);
                    break;
                case 2: // BOTTOM_LEFT
                    ctx.moveTo(0, h - r);
                    ctx.lineTo(0, h);
                    ctx.lineTo(r, h);
                    ctx.quadraticCurveTo(0, h, 0, h - r);
                    break;
                case 3: // BOTTOM_RIGHT
                    ctx.moveTo(w - r, h);
                    ctx.lineTo(w, h);
                    ctx.lineTo(w, h - r);
                    ctx.quadraticCurveTo(w, h, w - r, h);
                    break;
                }
            } else {
                // Original radius style
                const r = Math.max(0, Math.min(cornerShape.radius, Math.min(w, h)));
                const k = 0.55228475;

                switch (cornerShape.orientation) {
                case 0 // TOP_LEFT
                :
                    ctx.moveTo(0, r);
                    ctx.lineTo(0, 0);
                    ctx.lineTo(r, 0);
                    ctx.bezierCurveTo(r * (1 - k), 0, 0, r * (1 - k), 0, r);
                    break;
                case 1 // TOP_RIGHT
                :
                    ctx.moveTo(w - r, 0);
                    ctx.lineTo(w, 0);
                    ctx.lineTo(w, r);
                    ctx.bezierCurveTo(w, r * (1 - k), w - r * (1 - k), 0, w - r, 0);
                    break;
                case 2 // BOTTOM_LEFT
                :
                    ctx.moveTo(0, h - r);
                    ctx.lineTo(0, h);
                    ctx.lineTo(r, h);
                    ctx.bezierCurveTo(r * (1 - k), h, 0, h - r * (1 - k), 0, h - r);
                    break;
                case 3 // BOTTOM_RIGHT
                :
                    ctx.moveTo(w - r, h);
                    ctx.lineTo(w, h);
                    ctx.lineTo(w, h - r);
                    ctx.bezierCurveTo(w, h - r * (1 - k), w - r * (1 - k), h, w - r, h);
                    break;
                }
            }

            ctx.closePath();
            ctx.clip("evenodd"); // <-- subtracts corner curve from rectangle

            // fill remaining shape
            ctx.fillStyle = cornerShape.color;
            ctx.fillRect(0, 0, w, h);

            ctx.restore();
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }
}