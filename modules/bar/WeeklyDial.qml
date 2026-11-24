import QtQuick

// An open scale with quarter graduations. Bright ink ends at the reading.
Canvas {
    required property real usedPercent // -1: unavailable, not zero
    required property color ink
    required property color sweepInk
    implicitWidth: 27
    implicitHeight: 18
    antialiasing: true
    Accessible.ignored: true

    onUsedPercentChanged: requestPaint()
    onInkChanged: requestPaint()
    onSweepInkChanged: requestPaint()
    onPaint: {
        const c = getContext("2d");
        c.clearRect(0, 0, width, height);
        const cx = 13, cy = 14.5, radius = 11.5;
        const start = -Math.PI, end = start + Math.PI * Math.max(0, usedPercent) / 100;
        // Keep the single engraved rim and its graduations in the case ink.
        c.lineCap = "butt";
        c.lineWidth = 1.15;
        c.beginPath();
        c.arc(cx, cy, radius, start, 0);
        c.strokeStyle = Qt.alpha(ink, .55);
        c.stroke();

        // Two broken banks of dots flank the rim. Leave the four intervals
        // between graduations open at both ends; the needle remains clean.
        c.fillStyle = sweepInk;
        for (const [t, offset, nib] of [
            [.035, .81, .85], [.081, -1.15, .64], [.107, 1.03, .62], [.158, -.91, .83],
            [.194, .89, .91], [.284, .76, .83], [.318, -1.12, .72], [.349, 1.03, .65],
            [.395, -.99, .86], [.443, .89, .94], [.537, .84, .85], [.572, -1.12, .63],
            [.604, 1.02, .76], [.655, -.97, .84], [.697, .81, .89], [.787, .95, .89],
            [.823, -1.09, .69], [.862, .87, .8], [.91, -.96, .76], [.965, .82, .92]
        ]) {
            const a = start + Math.PI * t;
            if (a > end) break;
            c.beginPath();
            c.arc(cx + (radius + offset) * Math.cos(a), cy + (radius + offset) * Math.sin(a), nib, 0, 2 * Math.PI);
            c.fill();
        }

        c.lineWidth = 1;
        c.strokeStyle = Qt.alpha(ink, .75);
        c.beginPath();
        for (let i = 0; i <= 4; ++i) {
            const a = start + Math.PI * i / 4, u = Math.cos(a), v = Math.sin(a);
            const foot = i % 2 ? 9.9 : 9;
            c.moveTo(cx + radius * u, cy + radius * v);
            c.lineTo(cx + foot * u, cy + foot * v);
        }
        c.stroke();

        c.beginPath();
        if (usedPercent < 0) {
            c.moveTo(cx - 3, cy - 1);
            c.lineTo(cx + 3, cy - 1);
        } else {
            c.moveTo(cx, cy);
            c.lineTo(cx + 8.8 * Math.cos(end), cy + 8.8 * Math.sin(end));
        }
        c.strokeStyle = ink;
        c.lineWidth = usedPercent < 0 ? 1 : 1.85;
        c.stroke();
        if (usedPercent >= 0) {
            c.fillStyle = ink;
            c.beginPath();
            c.arc(cx, cy, 1.3, 0, Math.PI * 2);
            c.fill();
        }
    }
}
