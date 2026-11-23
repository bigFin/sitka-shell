import Quickshell.Widgets
import QtQuick
import "effects"

Item {
    id: root

    property color color: "transparent"
    property bool dithered: true
    property alias radius: clipping.radius
    property alias topLeftRadius: clipping.topLeftRadius
    property alias topRightRadius: clipping.topRightRadius
    property alias bottomLeftRadius: clipping.bottomLeftRadius
    property alias bottomRightRadius: clipping.bottomRightRadius
    property alias border: clipping.border
    property alias contentUnderBorder: clipping.contentUnderBorder
    property alias contentInsideBorder: clipping.contentInsideBorder
    readonly property alias contentItem: clipping.contentItem
    default property alias contentData: clipping.data

    antialiasing: radius > 0 || topLeftRadius > 0 || topRightRadius > 0 || bottomLeftRadius > 0 || bottomRightRadius > 0

    Behavior on color {
        CAnim {}
    }

    // Keep the native clipping/border implementation, but move the fill out
    // of its content capture. Text and artwork are never surface-filtered.
    data: [
        DitherSurface {
            id: dither
            anchors.fill: parent
            active: root.dithered
            color: root.color
            cornerSizes: Qt.vector4d(root.topLeftRadius, root.topRightRadius, root.bottomLeftRadius, root.bottomRightRadius)
            cornerStyles: Qt.vector4d(0, 0, 0, 0)
        },
        ClippingRectangle {
            id: clipping
            anchors.fill: parent
            color: dither.rendering ? "transparent" : root.color
            antialiasing: root.antialiasing
        }
    ]
}
