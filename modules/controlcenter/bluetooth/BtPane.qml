pragma ComponentBehavior: Bound

import ".."
import qs.components.effects
import qs.components.containers
import "../../../config"
import Quickshell.Widgets
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property Session session

    anchors.fill: parent

    spacing: 0

    Item {
        Layout.preferredWidth: Math.floor(parent.width * 0.4)
        Layout.minimumWidth: 420
        Layout.fillHeight: true

        DeviceList {
            anchors.fill: parent
            anchors.margins: Config.appearance.padding.large + Config.appearance.padding.normal
            anchors.leftMargin: Config.appearance.padding.large
            anchors.rightMargin: Config.appearance.padding.large + Config.appearance.padding.normal / 2

            session: root.session
        }

        InnerBorder {
            leftThickness: 0
            rightThickness: Config.appearance.padding.normal / 2
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: Config.appearance.padding.normal
            anchors.leftMargin: 0
            anchors.rightMargin: Config.appearance.padding.normal / 2

            radius: rightBorder.innerRadius
            color: "transparent"

            Loader {
                id: loader

                property BluetoothDevice pane: root.session.bt.active

                anchors.fill: parent
                anchors.margins: Config.appearance.padding.large * 2

                asynchronous: true
                sourceComponent: pane ? details : settings

                Behavior on pane {
                    SequentialAnimation {
                        ParallelAnimation {
                            Anim {
                                property: "opacity"
                                to: 0
                                easing.bezierCurve: Config.appearance.anim.curves.standardAccel
                            }
                            Anim {
                                property: "scale"
                                to: 0.8
                                easing.bezierCurve: Config.appearance.anim.curves.standardAccel
                            }
                        }
                        PropertyAction {}
                        ParallelAnimation {
                            Anim {
                                property: "opacity"
                                to: 1
                                easing.bezierCurve: Config.appearance.anim.curves.standardDecel
                            }
                            Anim {
                                property: "scale"
                                to: 1
                                easing.bezierCurve: Config.appearance.anim.curves.standardDecel
                            }
                        }
                    }
                }
            }
        }

        InnerBorder {
            id: rightBorder

            leftThickness: Config.appearance.padding.normal / 2
        }

        Component {
            id: settings

            StyledFlickable {
                flickableDirection: Flickable.VerticalFlick
                contentHeight: settingsInner.height

                Settings {
                    id: settingsInner

                    anchors.left: parent.left
                    anchors.right: parent.right
                    session: root.session
                }
            }
        }

        Component {
            id: details

            Details {
                session: root.session
            }
        }
    }

    component Anim: NumberAnimation {
        target: loader
        duration: Config.appearance.anim.durations.normal / 2
        easing.type: Easing.BezierSpline
    }
}
