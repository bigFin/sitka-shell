pragma ComponentBehavior: Bound

import qs.components
import qs.services
import "../../config"
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    readonly property alias unlocking: unlockAnim.running

    color: "transparent"

    Connections {
        target: root.lock

        function onUnlock(): void {
            unlockAnim.start();
        }
    }

    SequentialAnimation {
        id: unlockAnim

        ParallelAnimation {
            Anim {
                target: lockContent
                properties: "implicitWidth,implicitHeight"
                to: lockContent.size
                duration: Config.appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
            }
            Anim {
                target: lockBg
                property: "radius"
                to: lockContent.radius
            }
            Anim {
                target: content
                property: "scale"
                to: 0
                duration: Config.appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
            }
            Anim {
                target: content
                property: "opacity"
                to: 0
                duration: Config.appearance.anim.durations.small
            }
            Anim {
                target: lockIcon
                property: "opacity"
                to: 1
                duration: Config.appearance.anim.durations.large
            }
            Anim {
                target: background
                property: "opacity"
                to: 0
                duration: Config.appearance.anim.durations.large
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: Config.appearance.anim.durations.small
                }
                Anim {
                    target: lockContent
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
        id: initAnim

        running: true

        Anim {
            target: background
            property: "opacity"
            to: 1
            duration: Config.appearance.anim.durations.large
        }
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: lockContent
                    property: "scale"
                    to: 1
                    duration: Config.appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Config.appearance.anim.curves.expressiveFastSpatial
                }
                Anim {
                    target: lockContent
                    property: "rotation"
                    to: 360
                    duration: Config.appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Config.appearance.anim.curves.standardAccel
                }
            }
            ParallelAnimation {
                Anim {
                    target: lockIcon
                    property: "rotation"
                    to: 360
                    easing.bezierCurve: Config.appearance.anim.curves.standardDecel
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
                    property: "scale"
                    to: 1
                    duration: Config.appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
                }
                Anim {
                    target: lockBg
                    property: "radius"
                    to: Config.appearance.rounding.large * 1.5
                }
                Anim {
                    target: lockContent
                    property: "implicitWidth"
                    to: root.screen.height * Config.lock.sizes.heightMult * Config.lock.sizes.ratio
                    duration: Config.appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
                }
                Anim {
                    target: lockContent
                    property: "implicitHeight"
                    to: root.screen.height * Config.lock.sizes.heightMult
                    duration: Config.appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
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
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            blurMultiplier: 1
        }
    }

    Item {
        id: lockContent

        readonly property int size: lockIcon.implicitHeight + Config.appearance.padding.large * 4
        readonly property int radius: 0

        anchors.centerIn: parent
        implicitWidth: size
        implicitHeight: size

        rotation: 180
        scale: 0

        StyledRect {
            id: lockBg

            anchors.fill: parent
            color: Colours.palette.m3surface
            radius: parent.radius
            opacity: Colours.transparency.enabled ? Colours.transparency.base : 1
            
            // Apply large fillets for primary elements
            filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 15
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
            }
        }

        MaterialIcon {
            id: lockIcon

            anchors.centerIn: parent
            text: "lock"
            font.pointSize: Config.appearance.font.size.extraLarge * 4
            font.bold: true
            rotation: 180
        }

        Content {
            id: content

            anchors.centerIn: parent
            width: (root.screen?.height ?? 0) * Config.lock.sizes.heightMult * Config.lock.sizes.ratio - Config.appearance.padding.large * 2
            height: (root.screen?.height ?? 0) * Config.lock.sizes.heightMult - Config.appearance.padding.large * 2

            lock: root
            opacity: 0
            scale: 0
        }
    }
}
