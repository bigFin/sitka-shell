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

            RowLayout {
                Layout.fillWidth: true
                spacing: Config.appearance.spacing.small

                Item {
                    id: renameAdapter

                    Layout.fillWidth: true
                    Layout.rightMargin: Config.appearance.spacing.small

                    implicitHeight: renameLabel.implicitHeight + adapterNameEdit.implicitHeight

                    states: State {
                        name: "editingAdapterName"
                        when: root.session.bt.editingAdapterName

                        AnchorChanges {
                            target: adapterNameEdit
                            anchors.top: renameAdapter.top
                        }
                        PropertyChanges {
                            renameAdapter.implicitHeight: adapterNameEdit.implicitHeight
                            renameLabel.opacity: 0
                            adapterNameEdit.padding: Config.appearance.padding.normal
                        }
                    }

                    transitions: Transition {
                        AnchorAnimation {
                            duration: Config.appearance.anim.durations.normal
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Config.appearance.anim.curves.standard
                        }
                        Anim {
                            properties: "implicitHeight,opacity,padding"
                        }
                    }

                    StyledText {
                        id: renameLabel

                        anchors.left: parent.left

                        text: qsTr("Rename adapter (currently does not work)")  // FIXME: remove disclaimer when fixed
                        color: Colours.palette.m3outline
                        font.pointSize: Config.appearance.font.size.small
                    }

                    StyledTextField {
                        id: adapterNameEdit

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: renameLabel.bottom
                        anchors.leftMargin: root.session.bt.editingAdapterName ? 0 : -Config.appearance.padding.normal

                        text: root.session.bt.currentAdapter.name
                        readOnly: !root.session.bt.editingAdapterName
                        onAccepted: {
                            root.session.bt.editingAdapterName = false;
                            // Doesn't work for now, will be added to QS later
                            // root.session.bt.currentAdapter.name = text;
                        }

                        leftPadding: Config.appearance.padding.normal
                        rightPadding: Config.appearance.padding.normal

                        background: StyledRect {
                            radius: Config.appearance.rounding.small
                            border.width: 2
                            border.color: Colours.palette.m3primary
                            opacity: root.session.bt.editingAdapterName ? 1 : 0

                            Behavior on border.color {
                                CAnim {}
                            }

                            Behavior on opacity {
                                Anim {}
                            }
                        }

                        Behavior on anchors.leftMargin {
                            Anim {}
                        }
                    }
                }

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: cancelEditIcon.implicitHeight + Config.appearance.padding.smaller * 2

                    radius: Config.appearance.rounding.small
                    color: Colours.palette.m3secondaryContainer
                    opacity: root.session.bt.editingAdapterName ? 1 : 0
                    scale: root.session.bt.editingAdapterName ? 1 : 0.5

                    StateLayer {
                        color: Colours.palette.m3onSecondaryContainer
                        disabled: !root.session.bt.editingAdapterName

                        function onClicked(): void {
                            root.session.bt.editingAdapterName = false;
                            adapterNameEdit.text = Qt.binding(() => root.session.bt.currentAdapter.name);
                        }
                    }

                    MaterialIcon {
                        id: cancelEditIcon

                        anchors.centerIn: parent
                        animate: true
                        text: "cancel"
                        color: Colours.palette.m3onSecondaryContainer
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
                }

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: editIcon.implicitHeight + Config.appearance.padding.smaller * 2

                    radius: 0
                    color: Qt.alpha(Colours.palette.m3primary, root.session.bt.editingAdapterName ? 1 : 0)

                    StateLayer {
                        color: root.session.bt.editingAdapterName ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                        function onClicked(): void {
                            root.session.bt.editingAdapterName = !root.session.bt.editingAdapterName;
                            if (root.session.bt.editingAdapterName)
                                adapterNameEdit.forceActiveFocus();
                            else
                                adapterNameEdit.accepted();
                        }
                    }

                    MaterialIcon {
                        id: editIcon

                        anchors.centerIn: parent
                        animate: true
                        text: root.session.bt.editingAdapterName ? "check_circle" : "edit"
                        color: root.session.bt.editingAdapterName ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    }

                    Behavior on radius {
                        Anim {}
                    }
                }
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
