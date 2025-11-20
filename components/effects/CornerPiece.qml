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
            
            ctx.clearRect(0, 0, w, h);
            ctx.save();

            ctx.translate(cornerShape.invertH ? w : 0, cornerShape.invertV ? h : 0);
            ctx.scale(cornerShape.invertH ? -1 : 1, cornerShape.invertV ? -1 : 1);

            // Draw the positive shape of the corner piece
            ctx.beginPath();

            if (cornerShape.filletStyle === 1) {
                // Chamfer style (Diagonal Cut)
                // We need to draw a square with one corner cut off (the corner at 0,0 in local coords before rotation)
                // But wait, the rotation aligns the target corner to Top-Left (0,0).
                // So we want to fill the area *except* the chamfer at 0,0.
                
                const c = Math.max(0, Math.min(cornerShape.filletSize, Math.min(w, h)));
                
                switch (cornerShape.orientation) {
                case 0: // TOP_LEFT
                    ctx.moveTo(0, c);
                    ctx.lineTo(c, 0);
                    ctx.lineTo(w, 0);
                    ctx.lineTo(w, h);
                    ctx.lineTo(0, h);
                    ctx.lineTo(0, c);
                    break;
                case 1: // TOP_RIGHT
                    ctx.moveTo(w - c, 0);
                    ctx.lineTo(w, c);
                    ctx.lineTo(w, h);
                    ctx.lineTo(0, h);
                    ctx.lineTo(0, 0);
                    ctx.lineTo(w - c, 0);
                    break;
                case 2: // BOTTOM_LEFT
                    ctx.moveTo(0, h - c);
                    ctx.lineTo(c, h);
                    ctx.lineTo(w, h);
                    ctx.lineTo(w, 0);
                    ctx.lineTo(0, 0);
                    ctx.lineTo(0, h - c);
                    break;
                case 3: // BOTTOM_RIGHT
                    ctx.moveTo(w - c, h);
                    ctx.lineTo(w, h - c);
                    ctx.lineTo(w, 0);
                    ctx.lineTo(0, 0);
                    ctx.lineTo(0, h);
                    ctx.lineTo(w - c, h);
                    break;
                }
            } else if (cornerShape.filletStyle === 2) {
                // Fillet style (Rounded)
                const r = Math.max(0, Math.min(cornerShape.filletSize, Math.min(w, h)));
                
                switch (cornerShape.orientation) {
                case 0: // TOP_LEFT
                    ctx.moveTo(0, r);
                    ctx.quadraticCurveTo(0, 0, r, 0);
                    ctx.lineTo(w, 0);
                    ctx.lineTo(w, h);
                    ctx.lineTo(0, h);
                    ctx.lineTo(0, r);
                    break;
                case 1: // TOP_RIGHT
                    ctx.moveTo(w - r, 0);
                    ctx.quadraticCurveTo(w, 0, w, r);
                    ctx.lineTo(w, h);
                    ctx.lineTo(0, h);
                    ctx.lineTo(0, 0);
                    ctx.lineTo(w - r, 0);
                    break;
                case 2: // BOTTOM_LEFT
                    ctx.moveTo(0, h - r);
                    ctx.quadraticCurveTo(0, h, r, h);
                    ctx.lineTo(w, h);
                    ctx.lineTo(w, 0);
                    ctx.lineTo(0, 0);
                    ctx.lineTo(0, h - r);
                    break;
                case 3: // BOTTOM_RIGHT
                    ctx.moveTo(w - r, h);
                    ctx.quadraticCurveTo(w, h, w, h - r);
                    ctx.lineTo(w, 0);
                    ctx.lineTo(0, 0);
                    ctx.lineTo(0, h);
                    ctx.lineTo(w - r, h);
                    break;
                }
            } else {
                // Original radius style (Bezier)
                const r = Math.max(0, Math.min(cornerShape.radius, Math.min(w, h)));
                const k = 0.55228475;

                switch (cornerShape.orientation) {
                case 0: // TOP_LEFT
                    ctx.moveTo(0, r);
                    ctx.bezierCurveTo(0, r * (1 - k), r * (1 - k), 0, r, 0);
                    ctx.lineTo(w, 0);
                    ctx.lineTo(w, h);
                    ctx.lineTo(0, h);
                    ctx.lineTo(0, r);
                    break;
                case 1: // TOP_RIGHT
                    ctx.moveTo(w - r, 0);
                    ctx.bezierCurveTo(w - r * (1 - k), 0, w, r * (1 - k), w, r);
                    ctx.lineTo(w, h);
                    ctx.lineTo(0, h);
                    ctx.lineTo(0, 0);
                    ctx.lineTo(w - r, 0);
                    break;
                case 2: // BOTTOM_LEFT
                    ctx.moveTo(0, h - r);
                    ctx.bezierCurveTo(0, h - r * (1 - k), r * (1 - k), h, r, h);
                    ctx.lineTo(w, h);
                    ctx.lineTo(w, 0);
                    ctx.lineTo(0, 0);
                    ctx.lineTo(0, h - r);
                    break;
                case 3: // BOTTOM_RIGHT
                    ctx.moveTo(w - r, h);
                    ctx.bezierCurveTo(w, h - r * (1 - k), w - r * (1 - k), h, w - r, h);
                    ctx.lineTo(w, 0);
                    ctx.lineTo(0, 0);
                    ctx.lineTo(0, h);
                    ctx.lineTo(w - r, h);
                    break;
                }
            }

            ctx.closePath();
            
            // fill shape
            ctx.fillStyle = cornerShape.color;
            ctx.fill();

            ctx.restore();
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }
}