import "../config"
import QtQuick

ColorAnimation {
    duration: Config.appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Config.appearance.anim.curves.standard
}
