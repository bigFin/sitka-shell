pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import qs.config
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    property bool locked

    Component.onCompleted: locked = true

    color: "transparent"

    Connections {
        target: root.lock

        function onUnlock(): void {
            root.locked = false;
            unlockAnim.start();
        }
    }

    SequentialAnimation {
        id: unlockAnim

        ParallelAnimation {
            Anim {
                target: lockBg
                properties: "implicitWidth,implicitHeight"
                to: lockBg.size
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
            Anim {
                target: lockBg
                property: "radius"
                to: lockBg.size / 4
            }
            Anim {
                target: content
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.small
            }
            Anim {
                target: lockIcon
                property: "opacity"
                to: 1
            }
            Anim {
                target: background
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.large
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: Appearance.anim.durations.small
                }
                Anim {
                    target: lockBg
                    property: "opacity"
                    to: 0
                }
            }
        }
        PropertyAction {
            target: root.lock
            property: "locked"
            value: false
        }
    }

    ParallelAnimation {
        running: true

        Anim {
            target: background
            property: "opacity"
            to: 1
            duration: Appearance.anim.durations.large
        }
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: lockBg
                    property: "scale"
                    to: 1
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                }
                Anim {
                    target: lockBg
                    property: "rotation"
                    to: 360
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.standardAccel
                }
            }
            ParallelAnimation {
                Anim {
                    target: lockIcon
                    property: "rotation"
                    to: 360
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
                Anim {
                    target: lockIcon
                    property: "opacity"
                    to: 0
                }
                Anim {
                    target: content
                    property: "opacity"
                    to: 1
                }
                Anim {
                    target: content
                    property: "centerScale"
                    to: 1
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
                Anim {
                    target: lockBg
                    property: "radius"
                    to: Appearance.rounding.large
                }
                Anim {
                    target: lockBg
                    property: "implicitWidth"
                    to: root.screen.height * Config.lock.sizes.heightMult * Config.lock.sizes.ratio
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
                Anim {
                    target: lockBg
                    property: "implicitHeight"
                    to: root.screen.height * Config.lock.sizes.heightMult
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
        }
    }

    ScreencopyView {
        id: background

        anchors.fill: parent
        captureSource: root.screen
        opacity: 0

        layer.enabled: true
        layer.effect: MultiEffect {
            id: backgroundBlur

            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            blurMultiplier: 1
        }
    }

    StyledRect {
        id: lockBg

        readonly property int size: lockIcon.implicitHeight + Appearance.padding.large * 4

        anchors.centerIn: parent
        implicitWidth: size
        implicitHeight: size

        clip: true
        color: Colours.tPalette.m3surface
        radius: size / 4
        rotation: 180
        scale: 0

        Elevation {
            anchors.fill: parent
            radius: parent.radius
            z: -1
            level: 3
            offset.y: 0
        }

        MaterialIcon {
            id: lockIcon

            anchors.centerIn: parent
            text: "lock"
            font.pointSize: Appearance.font.size.extraLarge * 4
            font.bold: true
            rotation: 180
        }

        Content {
            id: content

            lock: root
            opacity: 0
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
