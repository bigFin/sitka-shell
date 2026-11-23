pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import "../../../config"
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Config.appearance.spacing.normal

    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        text: "bluetooth"
        font.pointSize: Config.appearance.font.size.extraLarge * 3
        font.bold: true
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: qsTr("Bluetooth settings")
        font.pointSize: Config.appearance.font.size.large
        font.bold: true
    }

    StyledText {
        Layout.topMargin: Config.appearance.spacing.large
        text: qsTr("Adapter status")
        font.pointSize: Config.appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("General adapter settings")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: adapterStatus.implicitHeight + Config.appearance.padding.large * 2

        radius: Config.appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: adapterStatus

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Config.appearance.padding.large

            spacing: Config.appearance.spacing.larger

            Toggle {
                label: qsTr("Powered")
                checked: Bluetooth.defaultAdapter?.enabled ?? false
                toggle.onToggled: {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.enabled = checked;
                }
            }

            Toggle {
                label: qsTr("Discoverable")
                checked: Bluetooth.defaultAdapter?.discoverable ?? false
                toggle.onToggled: {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.discoverable = checked;
                }
            }

            Toggle {
                label: qsTr("Pairable")
                checked: Bluetooth.defaultAdapter?.pairable ?? false
                toggle.onToggled: {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.pairable = checked;
                }
            }
        }
    }

    StyledText {
        Layout.topMargin: Config.appearance.spacing.large
        text: qsTr("Adapter properties")
        font.pointSize: Config.appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Per-adapter settings")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: adapterSettings.implicitHeight + Config.appearance.padding.large * 2

        radius: Config.appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: adapterSettings

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Config.appearance.padding.large

            spacing: Config.appearance.spacing.larger

            RowLayout {
                Layout.fillWidth: true
                spacing: Config.appearance.spacing.normal

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Current adapter")
                }

                Item {
                    id: adapterPickerButton

                    property bool expanded

                    implicitWidth: adapterPicker.implicitWidth + Config.appearance.padding.normal * 2
                    implicitHeight: adapterPicker.implicitHeight + Config.appearance.padding.smaller * 2

                    StateLayer {
                        radius: Config.appearance.rounding.small

                        function onClicked(): void {
                            adapterPickerButton.expanded = !adapterPickerButton.expanded;
                        }
                    }

                    RowLayout {
                        id: adapterPicker

                        anchors.fill: parent
                        anchors.margins: Config.appearance.padding.normal
                        anchors.topMargin: Config.appearance.padding.smaller
                        anchors.bottomMargin: Config.appearance.padding.smaller
                        spacing: Config.appearance.spacing.normal

                        StyledText {
                            Layout.leftMargin: Config.appearance.padding.small
                            text: Bluetooth.defaultAdapter?.name ?? qsTr("None")
                        }

                        MaterialIcon {
                            text: "expand_more"
                        }
                    }

                    Elevation {
                        anchors.fill: adapterListBg
                        radius: adapterListBg.radius
                        opacity: adapterPickerButton.expanded ? 1 : 0
                        scale: adapterPickerButton.expanded ? 1 : 0.7
                        level: 2

                        Behavior on opacity {
                            Anim {}
                        }

                        Behavior on scale {
                            Anim {
                                duration: Config.appearance.anim.durations.expressiveFastSpatial
                                easing.bezierCurve: Config.appearance.anim.curves.expressiveFastSpatial
                            }
                        }
                    }

                    StyledClippingRect {
                        id: adapterListBg

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        implicitHeight: adapterPickerButton.expanded ? adapterList.implicitHeight : adapterPickerButton.implicitHeight

                        color: Colours.palette.m3secondaryContainer
                        radius: Config.appearance.rounding.small
                        opacity: adapterPickerButton.expanded ? 1 : 0
                        scale: adapterPickerButton.expanded ? 1 : 0.7

                        ColumnLayout {
                            id: adapterList

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            spacing: 0

                            Repeater {
                                model: Bluetooth.adapters

                                Item {
                                    id: adapter

                                    required property BluetoothAdapter modelData

                                    Layout.fillWidth: true
                                    implicitHeight: adapterInner.implicitHeight + Config.appearance.padding.normal * 2

                                    StateLayer {
                                        disabled: !adapterPickerButton.expanded

                                        function onClicked(): void {
                                            adapterPickerButton.expanded = false;
                                            root.session.bt.currentAdapter = adapter.modelData;
                                        }
                                    }

                                    RowLayout {
                                        id: adapterInner

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.margins: Config.appearance.padding.normal
                                        spacing: Config.appearance.spacing.normal

                                        StyledText {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: Config.appearance.padding.small
                                            text: adapter.modelData.name
                                            color: Colours.palette.m3onSecondaryContainer
                                        }

                                        MaterialIcon {
                                            text: "check"
                                            color: Colours.palette.m3onSecondaryContainer
                                            visible: adapter.modelData === root.session.bt.currentAdapter
                                        }
                                    }
                                }
                            }
                        }

                        Behavior on opacity {
                            Anim {}
                        }

                        Behavior on scale {
                            Anim {
                                duration: Config.appearance.anim.durations.expressiveFastSpatial
                                easing.bezierCurve: Config.appearance.anim.curves.expressiveFastSpatial
                            }
                        }

                        Behavior on implicitHeight {
                            Anim {
                                duration: Config.appearance.anim.durations.expressiveDefaultSpatial
                                easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Config.appearance.spacing.normal

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Discoverable timeout")
                }

                CustomSpinBox {
                    min: 0
                    value: root.session.bt.currentAdapter.discoverableTimeout
                    onValueModified: value => root.session.bt.currentAdapter.discoverableTimeout = value
                }
            }

            RenameEditor {
                label: qsTr("Rename adapter (currently does not work)")
                modelName: root.session.bt.currentAdapter?.name ?? ""
                editing: root.session.bt.editingAdapterName
                onEditingRequested: active => root.session.bt.editingAdapterName = active
                // No onAccepted write: Quickshell cannot rename adapters yet.
            }
        }
    }

    StyledText {
        Layout.topMargin: Config.appearance.spacing.large
        text: qsTr("Adapter information")
        font.pointSize: Config.appearance.font.size.larger
        font.weight: 500
    }

    StyledText {
        text: qsTr("Information about the default adapter")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: adapterInfo.implicitHeight + Config.appearance.padding.large * 2

        radius: Config.appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: adapterInfo

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Config.appearance.padding.large

            spacing: Config.appearance.spacing.small / 2

            StyledText {
                text: qsTr("Adapter state")
            }

            StyledText {
                text: Bluetooth.defaultAdapter ? BluetoothAdapterState.toString(Bluetooth.defaultAdapter.state) : qsTr("Unknown")
                color: Colours.palette.m3outline
                font.pointSize: Config.appearance.font.size.small
            }

            StyledText {
                Layout.topMargin: Config.appearance.spacing.normal
                text: qsTr("Dbus path")
            }

            StyledText {
                text: Bluetooth.defaultAdapter?.dbusPath ?? ""
                color: Colours.palette.m3outline
                font.pointSize: Config.appearance.font.size.small
            }

            StyledText {
                Layout.topMargin: Config.appearance.spacing.normal
                text: qsTr("Adapter id")
            }

            StyledText {
                text: Bluetooth.defaultAdapter?.adapterId ?? ""
                color: Colours.palette.m3outline
                font.pointSize: Config.appearance.font.size.small
            }
        }
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        spacing: Config.appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle

            cLayer: 2
        }
    }
}
