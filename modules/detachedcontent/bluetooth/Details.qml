pragma ComponentBehavior: Bound

import ".."
import qs.widgets
import qs.services
import qs.config
import qs.utils
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session
    readonly property BluetoothDevice device: session.bt.active

    StyledFlickable {
        anchors.fill: parent

        flickableDirection: Flickable.VerticalFlick
        contentHeight: layout.height

        ColumnLayout {
            id: layout

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: Icons.getBluetoothIcon(root.device.icon)
                font.pointSize: Appearance.font.size.extraLarge * 3
                font.bold: true
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.device.name
                font.pointSize: Appearance.font.size.large
                font.bold: true
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.large
                text: qsTr("Connection status")
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Connection settings for this device")
                color: Colours.palette.m3outline
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: adapterStatus.implicitHeight + Appearance.padding.large * 2

                radius: Appearance.rounding.normal
                color: Colours.palette.m3surfaceContainer

                ColumnLayout {
                    id: adapterStatus

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Appearance.padding.large

                    spacing: Appearance.spacing.larger

                    Toggle {
                        label: qsTr("Connected")
                        checked: root.device.connected
                        toggle.onToggled: root.device.connected = checked
                    }

                    Toggle {
                        label: qsTr("Paired")
                        checked: root.device.paired
                        toggle.onToggled: {
                            if (root.device.paired)
                                root.device.forget();
                            else
                                root.device.pair();
                        }
                    }

                    Toggle {
                        label: qsTr("Blocked")
                        checked: root.device.blocked
                        toggle.onToggled: root.device.blocked = checked
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.right: fabRoot.right
        anchors.bottom: fabRoot.top
        anchors.bottomMargin: Appearance.padding.normal

        Repeater {
            id: fabMenu

            model: ListModel {
                ListElement {
                    name: "trust"
                    icon: "handshake"
                }
                ListElement {
                    name: "block"
                    icon: "block"
                }
                ListElement {
                    name: "pair"
                    icon: "missing_controller"
                }
                ListElement {
                    name: "connect"
                    icon: "bluetooth_connected"
                }
            }

            StyledClippingRect {
                id: fabMenuItem

                required property var modelData
                required property int index

                Layout.alignment: Qt.AlignRight

                implicitHeight: fabMenuItemInner.implicitHeight + Appearance.padding.larger * 2

                radius: Appearance.rounding.full
                color: Colours.palette.m3primaryContainer

                opacity: 0

                states: State {
                    name: "visible"
                    when: root.session.bt.fabMenuOpen

                    PropertyChanges {
                        fabMenuItem.implicitWidth: fabMenuItemInner.implicitWidth + Appearance.padding.large * 2
                        fabMenuItem.opacity: 1
                        fabMenuItemInner.opacity: 1
                    }
                }

                transitions: [
                    Transition {
                        to: "visible"

                        SequentialAnimation {
                            PauseAnimation {
                                duration: (fabMenu.count - 1 - fabMenuItem.index) * Appearance.anim.durations.small / 8
                            }
                            ParallelAnimation {
                                Anim {
                                    property: "implicitWidth"
                                    duration: Appearance.anim.durations.expressiveFastSpatial
                                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                                }
                                Anim {
                                    property: "opacity"
                                    duration: Appearance.anim.durations.small
                                }
                            }
                        }
                    },
                    Transition {
                        from: "visible"

                        SequentialAnimation {
                            PauseAnimation {
                                duration: fabMenuItem.index * Appearance.anim.durations.small / 8
                            }
                            ParallelAnimation {
                                Anim {
                                    property: "implicitWidth"
                                    duration: Appearance.anim.durations.expressiveFastSpatial
                                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                                }
                                Anim {
                                    property: "opacity"
                                    duration: Appearance.anim.durations.small
                                }
                            }
                        }
                    }
                ]

                StateLayer {
                    function onClicked(): void {
                        root.session.bt.fabMenuOpen = false;

                        const name = fabMenuItem.modelData.name;
                        if (fabMenuItem.modelData.name !== "pair")
                            root.device[`${name}ed`] = !root.device[`${name}ed`];
                        else if (root.device.paired)
                            root.device.forget();
                        else
                            root.device.pair();
                    }
                }

                RowLayout {
                    id: fabMenuItemInner

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.normal
                    opacity: 0

                    MaterialIcon {
                        text: fabMenuItem.modelData.icon
                        color: Colours.palette.m3onPrimaryContainer
                        fill: 1
                    }

                    StyledText {
                        animate: true
                        text: (root.device[`${fabMenuItem.modelData.name}ed`] ? fabMenuItem.modelData.name === "connect" ? "dis" : "un" : "") + fabMenuItem.modelData.name
                        color: Colours.palette.m3onPrimaryContainer
                        font.capitalization: Font.Capitalize
                        Layout.preferredWidth: implicitWidth

                        Behavior on Layout.preferredWidth {
                            Anim {
                                duration: Appearance.anim.durations.small
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: fabRoot

        anchors.right: parent.right
        anchors.bottom: parent.bottom

        implicitWidth: 64
        implicitHeight: 64

        StyledRect {
            id: fabBg

            anchors.right: parent.right
            anchors.top: parent.top

            implicitWidth: 64
            implicitHeight: 64

            radius: Appearance.rounding.normal
            color: root.session.bt.fabMenuOpen ? Colours.palette.m3primary : Colours.palette.m3primaryContainer

            states: State {
                name: "expanded"
                when: root.session.bt.fabMenuOpen

                PropertyChanges {
                    fabBg.implicitWidth: 48
                    fabBg.implicitHeight: 48
                    fabBg.radius: 48 / 2
                    fab.font.pointSize: Appearance.font.size.larger
                }
            }

            transitions: Transition {
                Anim {
                    properties: "implicitWidth,implicitHeight"
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                }
                Anim {
                    properties: "radius,font.pointSize"
                }
            }

            Elevation {
                anchors.fill: parent
                radius: parent.radius
                z: -1
                level: fabState.containsMouse && !fabState.pressed ? 4 : 3
            }

            StateLayer {
                id: fabState

                color: root.session.bt.fabMenuOpen ? Colours.palette.m3onPrimary : Colours.palette.m3onPrimaryContainer

                function onClicked(): void {
                    root.session.bt.fabMenuOpen = !root.session.bt.fabMenuOpen;
                }
            }

            MaterialIcon {
                id: fab

                anchors.centerIn: parent
                animate: true
                text: root.session.bt.fabMenuOpen ? "close" : "settings"
                color: root.session.bt.fabMenuOpen ? Colours.palette.m3onPrimary : Colours.palette.m3onPrimaryContainer
                font.pointSize: Appearance.font.size.large
                fill: 1
            }
        }
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
