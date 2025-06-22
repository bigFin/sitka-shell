import "root:/widgets"
import "root:/services"
import "root:/config"
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects

Item {
    id: root

    required property bool locked

    readonly property real clockBottom: innerMask.anchors.margins + clockPath.height
    readonly property real inputTop: innerMask.anchors.margins + inputPath.height

    anchors.fill: parent

    StyledRect {
        id: base

        anchors.fill: parent
        color: Colours.alpha(Config.border.colour, false)
        visible: false
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            id: innerMask

            anchors.fill: parent
            anchors.margins: root.locked ? root.height * Config.lock.sizes.border : 0
            anchors.leftMargin: root.locked ? root.width * Config.lock.sizes.border : 0
            anchors.rightMargin: root.locked ? root.width * Config.lock.sizes.border : 0

            radius: Appearance.rounding.large * 2

            Behavior on anchors.margins {
                Anim {}
            }

            Behavior on anchors.leftMargin {
                Anim {}
            }

            Behavior on anchors.rightMargin {
                Anim {}
            }
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: base
        maskEnabled: true
        maskInverted: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Shape {
        anchors.fill: parent
        anchors.margins: Math.floor(innerMask.anchors.margins)
        anchors.leftMargin: innerMask.anchors.leftMargin
        anchors.rightMargin: innerMask.anchors.rightMargin

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: clockPath

            readonly property int width: Config.lock.sizes.clockWidth
            property real height: root.locked ? Config.lock.sizes.clockHeight : 0

            readonly property real rounding: Appearance.rounding.large * 4
            readonly property bool flatten: height < rounding * 2
            readonly property real roundingY: flatten ? height / 2 : rounding

            strokeWidth: -1
            fillColor: Config.border.colour

            startX: (innerMask.width - width) / 2 - rounding

            PathArc {
                relativeX: clockPath.rounding
                relativeY: clockPath.roundingY
                radiusX: clockPath.rounding
                radiusY: Math.min(clockPath.rounding, clockPath.height)
            }
            PathLine {
                relativeX: 0
                relativeY: clockPath.height - clockPath.roundingY * 2
            }
            PathArc {
                relativeX: clockPath.rounding
                relativeY: clockPath.roundingY
                radiusX: clockPath.rounding
                radiusY: Math.min(clockPath.rounding, clockPath.height)
                direction: PathArc.Counterclockwise
            }
            PathLine {
                relativeX: clockPath.width - clockPath.rounding * 2
                relativeY: 0
            }
            PathArc {
                relativeX: clockPath.rounding
                relativeY: -clockPath.roundingY
                radiusX: clockPath.rounding
                radiusY: Math.min(clockPath.rounding, clockPath.height)
                direction: PathArc.Counterclockwise
            }
            PathLine {
                relativeX: 0
                relativeY: -(clockPath.height - clockPath.roundingY * 2)
            }
            PathArc {
                relativeX: clockPath.rounding
                relativeY: -clockPath.roundingY
                radiusX: clockPath.rounding
                radiusY: Math.min(clockPath.rounding, clockPath.height)
            }

            Behavior on height {
                Anim {}
            }

            Behavior on fillColor {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }

        ShapePath {
            id: inputPath

            readonly property int width: Config.lock.sizes.inputWidth
            property real height: root.locked ? Config.lock.sizes.inputHeight : 0

            readonly property real rounding: Appearance.rounding.large * 2
            readonly property bool flatten: height < rounding * 2
            readonly property real roundingY: flatten ? height / 2 : rounding

            strokeWidth: -1
            fillColor: Config.border.colour

            startX: (innerMask.width - width) / 2 - rounding
            startY: Math.ceil(innerMask.height)

            PathArc {
                relativeX: inputPath.rounding
                relativeY: -inputPath.roundingY
                radiusX: inputPath.rounding
                radiusY: Math.min(inputPath.rounding, inputPath.height)
                direction: PathArc.Counterclockwise
            }
            PathLine {
                relativeX: 0
                relativeY: -(inputPath.height - inputPath.roundingY * 2)
            }
            PathArc {
                relativeX: inputPath.rounding
                relativeY: -inputPath.roundingY
                radiusX: inputPath.rounding
                radiusY: Math.min(inputPath.rounding, inputPath.height)
            }
            PathLine {
                relativeX: inputPath.width - inputPath.rounding * 2
                relativeY: 0
            }
            PathArc {
                relativeX: inputPath.rounding
                relativeY: inputPath.roundingY
                radiusX: inputPath.rounding
                radiusY: Math.min(inputPath.rounding, inputPath.height)
            }
            PathLine {
                relativeX: 0
                relativeY: inputPath.height - inputPath.roundingY * 2
            }
            PathArc {
                relativeX: inputPath.rounding
                relativeY: inputPath.roundingY
                radiusX: inputPath.rounding
                radiusY: Math.min(inputPath.rounding, inputPath.height)
                direction: PathArc.Counterclockwise
            }

            Behavior on height {
                Anim {}
            }

            Behavior on fillColor {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.large
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.emphasized
    }
}
