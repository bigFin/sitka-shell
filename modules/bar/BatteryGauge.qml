import QtQuick

// Side elevation: the single case line steps out to form the terminal.
Canvas {
    required property real level // 0..1, or -1 for an unreported level
    required property bool charging
    required property color ink
    required property color fillInk
    implicitWidth: 36
    implicitHeight: 15
    antialiasing: true
    Accessible.ignored: true

    onLevelChanged: requestPaint()
    onChargingChanged: requestPaint()
    onInkChanged: requestPaint()
    onFillInkChanged: requestPaint()
    onPaint: {
        const c = getContext("2d");
        c.clearRect(0, 0, width, height);
        c.lineWidth = 1;
        c.lineJoin = "miter";
        c.lineCap = "butt";
        c.strokeStyle = Qt.alpha(ink, .83);
        c.beginPath();
        c.moveTo(1.5, 2.5);
        c.lineTo(24.5, 2.5);
        c.lineTo(24.5, 5.5);
        c.lineTo(27.5, 5.5);
        c.lineTo(27.5, 9.5);
        c.lineTo(24.5, 9.5);
        c.lineTo(24.5, 12.5);
        c.lineTo(1.5, 12.5);
        c.closePath();
        c.stroke();

        c.strokeStyle = ink;
        if (charging) {
            c.beginPath();
            c.moveTo(30, 7.5);
            c.lineTo(35, 7.5);
            c.moveTo(32.5, 5);
            c.lineTo(32.5, 10);
            c.stroke();
        }
        if (level < 0) {
            c.beginPath();
            c.moveTo(10, 7.5);
            c.lineTo(16, 7.5);
            c.stroke();
        } else if (level > 0) {
            // Reveal one fixed field through a moving edge. The spaces between
            // the marks are bare metal, including at full charge.
            c.save();
            c.beginPath();
            c.rect(4, 4, 19 * level, 7);
            c.clip();
            c.fillStyle = fillInk;
            for (const [x, y, r] of [
                [.63, 1.2, .86], [1.65, 3.35, .63], [.6, 5.8, .91],
                [3.28, .7, .55], [3.88, 2.66, .95], [2.95, 5.14, .84],
                [5.96, 1.37, .87], [5.28, 4.65, .59], [6.61, 6.1, .8],
                [7.33, 3.63, .99], [8.63, .72, .58], [9.6, 2.3, .73],
                [9.05, 5.62, .93], [10.83, 4.14, .6], [11.48, .98, .93],
                [12.23, 5.82, .83], [13.31, 3.35, .99], [14.3, .75, .57],
                [14.66, 5.4, .8], [15.67, 2.05, .87], [16.74, 4.1, .64],
                [17.12, 6.25, .85], [18.44, .7, .71], [18.35, 3.14, .9]
            ]) {
                c.beginPath();
                c.arc(4 + x, 4 + y, r, 0, 2 * Math.PI);
                c.fill();
            }
            c.restore();
        }
    }
}
