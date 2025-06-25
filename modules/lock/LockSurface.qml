import "root:/widgets"
import "root:/services"
import "root:/config"
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock

    property bool thisLocked
    readonly property bool locked: thisLocked && !lock.unlocked

    function unlock(): void {
        lock.unlocked = true;
        animDelay.start();
    }

    Component.onCompleted: thisLocked = true

    color: "transparent"

    Timer {
        id: animDelay

        interval: Appearance.anim.durations.large
        onTriggered: root.lock.locked = false
    }

    Connections {
        target: root.lock

        function onUnlockedChanged(): void {
            background.opacity = 0;
        }
    }

    ScreencopyView {
        id: screencopy

        anchors.fill: parent
        captureSource: root.screen
        visible: false
    }

    MultiEffect {
        id: background

        anchors.fill: parent

        source: screencopy
        autoPaddingEnabled: false
        blurEnabled: true
        blur: root.locked ? 1 : 0
        blurMax: 64
        blurMultiplier: 1

        Behavior on opacity {
            Anim {}
        }

        Behavior on blur {
            Anim {}
        }
    }

    Backgrounds {
        id: backgrounds

        locked: root.locked
        weatherWidth: weather.implicitWidth
        isLarge: root.screen.width > 1920
        visible: false
    }

    MultiEffect {
        anchors.fill: source
        source: backgrounds
        shadowEnabled: true
        blurMax: 15
        shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
    }

    Clock {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: -backgrounds.clockBottom

        locked: root.locked
    }

    Input {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: -backgrounds.inputTop

        lock: root
    }

    WeatherInfo {
        id: weather

        anchors.top: parent.bottom
        anchors.right: parent.left
        anchors.topMargin: -backgrounds.weatherTop
        anchors.rightMargin: -backgrounds.weatherRight
    }

    MediaPlaying {
        id: media

        isLarge: root.screen.width > 1920

        state: isLarge ? "tl" : "br"
        states: [
            State {
                name: "tl"

                AnchorChanges {
                    target: media
                    anchors.bottom: media.parent.top
                    anchors.right: media.parent.left
                }

                PropertyChanges {
                    media.anchors.bottomMargin: -backgrounds.mediaY
                    media.anchors.rightMargin: -backgrounds.mediaX
                }
            },
            State {
                name: "br"

                AnchorChanges {
                    target: media
                    anchors.top: media.parent.bottom
                    anchors.left: media.parent.right
                }

                PropertyChanges {
                    media.anchors.topMargin: -backgrounds.mediaY
                    media.anchors.leftMargin: -backgrounds.mediaX
                }
            }
        ]
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.large
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
