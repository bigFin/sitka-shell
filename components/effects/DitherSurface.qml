import QtQuick
import Sitka
import "../../config"

// A fill, not a filter on a control. It never captures child text or icons.
Item {
    id: root

    property bool active: true
    property color color: "transparent"
    property vector4d cornerSizes: Qt.vector4d(0, 0, 0, 0)
    // -2: empty corner, -1: square, 0: circle, 1: chamfer, 2: quadratic fillet.
    property vector4d cornerStyles: Qt.vector4d(-1, -1, -1, -1)
    property int triangle: -1
    property bool composedFill: false
    property real relief: 0
    readonly property real intensity: Math.max(0, Math.min(1, Config.appearance.dithering.intensity))
    readonly property real pixelSize: Math.max(1, Math.min(8, Config.appearance.dithering.pixelSize))
    readonly property bool supported: GraphicsInfo.api !== GraphicsInfo.Software && GraphicsInfo.api !== GraphicsInfo.Unknown && GraphicsInfo.api !== GraphicsInfo.Null
    readonly property bool rendering: shaderLoader.item !== null && shaderLoader.item.status !== ShaderEffect.Error

    Loader {
        id: shaderLoader
        anchors.fill: parent
        active: root.active && root.visible && root.opacity > 0 && root.width > 2 && root.height > 2 && root.color.a > 0
                && root.supported && Config.appearance.dithering.enabled && root.intensity > 0

        sourceComponent: ShaderEffect {
            readonly property color baseColor: root.color
            readonly property vector2d surfaceSize: Qt.vector2d(width, height)
            readonly property vector4d cornerSizes: root.cornerSizes
            readonly property vector4d cornerStyles: root.cornerStyles
            readonly property real intensity: root.intensity
            readonly property real cellSize: Math.max(1, Math.round(root.pixelSize * (root.Window.window?.devicePixelRatio ?? 1)))
            readonly property int triangle: root.triangle
            readonly property bool composedFill: root.composedFill
            readonly property real relief: root.relief
            fragmentShader: "qrc:/sitka/shaders/dither-surface.frag.qsb"
            visible: status !== ShaderEffect.Error
        }
    }
}
