pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import "../../../config"
import qs.utils
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: root

    required property Session session
    readonly property bool smallDiscoverable: width <= 540
    readonly property bool smallPairable: width <= 480

    spacing: Config.appearance.spacing.small

    RowLayout {
        spacing: Config.appearance.spacing.smaller

        StyledText {
            text: qsTr("Settings")
            font.pointSize: Config.appearance.font.size.large
            font.weight: 500
        }

        Item {
            Layout.fillWidth: true
        }

        ToggleButton {
            toggled: Bluetooth.defaultAdapter?.enabled ?? false
            icon: "power"
            accent: "Tertiary"

            function onClicked(): void {
                const adapter = Bluetooth.defaultAdapter;
                if (adapter)
                    adapter.enabled = !adapter.enabled;
            }
        }

        ToggleButton {
            toggled: Bluetooth.defaultAdapter?.discoverable ?? false
            icon: root.smallDiscoverable ? "group_search" : ""
            label: root.smallDiscoverable ? "" : qsTr("Discoverable")

            function onClicked(): void {
                const adapter = Bluetooth.defaultAdapter;
                if (adapter)
                    adapter.discoverable = !adapter.discoverable;
            }
        }

        ToggleButton {
            toggled: Bluetooth.defaultAdapter?.pairable ?? false
            icon: "missing_controller"
            label: root.smallPairable ? "" : qsTr("Pairable")

            function onClicked(): void {
                const adapter = Bluetooth.defaultAdapter;
                if (adapter)
                    adapter.pairable = !adapter.pairable;
            }
        }

        ToggleButton {
            toggled: !root.session.bt.active
            icon: "settings"
            accent: "Primary"

            function onClicked(): void {
                if (root.session.bt.active)
                    root.session.bt.active = null;
                else {
                    root.session.bt.active = deviceModel.values[0] ?? null;
                }
            }
        }
    }

    RowLayout {
        Layout.topMargin: Config.appearance.spacing.large
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.normal

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Config.appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Devices (%1)").arg(Bluetooth.devices.values.length)
                font.pointSize: Config.appearance.font.size.large
                font.weight: 500
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("All available bluetooth devices")
                color: Colours.palette.m3outline
            }
        }

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: scanIcon.implicitHeight + Config.appearance.padding.normal * 2

            radius: 0
            color: Bluetooth.defaultAdapter?.discovering ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer
            
            // Apply normal fillets for secondary elements
            filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.normal : 4

            StateLayer {
                color: Bluetooth.defaultAdapter?.discovering ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer

                function onClicked(): void {
                    const adapter = Bluetooth.defaultAdapter;
                    if (adapter)
                        adapter.discovering = !adapter.discovering;
                }
            }

            MaterialIcon {
                id: scanIcon

                anchors.centerIn: parent
                animate: true
                text: "bluetooth_searching"
                color: Bluetooth.defaultAdapter?.discovering ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                fill: Bluetooth.defaultAdapter?.discovering ? 1 : 0
            }

            Behavior on radius {
                Anim {}
            }
        }
    }

    StyledListView {
        model: ScriptModel {
            id: deviceModel
            values: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))
        }

        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Config.appearance.spacing.small / 2

        ScrollBar.vertical: StyledScrollBar {}

        delegate: StyledRect {
            id: device

            required property BluetoothDevice modelData
            readonly property bool loading: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
            readonly property bool connected: modelData.state === BluetoothDeviceState.Connected

            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: deviceInner.implicitHeight + Config.appearance.padding.normal * 2

            color: Qt.alpha(Colours.tPalette.m3surfaceContainer, root.session.bt.active === modelData ? Colours.tPalette.m3surfaceContainer.a : 0)
            radius: Config.appearance.rounding.normal

            StateLayer {
                id: stateLayer

                function onClicked(): void {
                    root.session.bt.active = device.modelData;
                }
            }

            RowLayout {
                id: deviceInner

                anchors.fill: parent
                anchors.margins: Config.appearance.padding.normal

                spacing: Config.appearance.spacing.normal

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: icon.implicitHeight + Config.appearance.padding.normal * 2

                    radius: Config.appearance.rounding.normal
                    color: device.connected ? Colours.palette.m3primaryContainer : device.modelData.bonded ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh

                    StyledRect {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.alpha(device.connected ? Colours.palette.m3onPrimaryContainer : device.modelData.bonded ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface, stateLayer.pressed ? 0.1 : stateLayer.containsMouse ? 0.08 : 0)
                    }

                    MaterialIcon {
                        id: icon

                        anchors.centerIn: parent
                        text: Icons.getBluetoothIcon(device.modelData.icon)
                        color: device.connected ? Colours.palette.m3onPrimaryContainer : device.modelData.bonded ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        font.pointSize: Config.appearance.font.size.large
                        fill: device.connected ? 1 : 0

                        Behavior on fill {
                            Anim {}
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: device.modelData.name
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: device.modelData.address + (device.connected ? qsTr(" (Connected)") : device.modelData.bonded ? qsTr(" (Paired)") : "")
                        color: Colours.palette.m3outline
                        font.pointSize: Config.appearance.font.size.small
                        elide: Text.ElideRight
                    }
                }

                StyledRect {
                    id: connectBtn

                    implicitWidth: implicitHeight
                    implicitHeight: connectIcon.implicitHeight + Config.appearance.padding.smaller * 2

                    radius: Config.appearance.rounding.full
                    color: device.connected ? Colours.palette.m3primaryContainer : "transparent"

                    StyledBusyIndicator {
                        anchors.fill: parent
                        running: device.loading
                    }

                    StateLayer {
                        color: device.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                        disabled: device.loading

                        function onClicked(): void {
                            device.modelData.connected = !device.modelData.connected;
                        }
                    }

                    MaterialIcon {
                        id: connectIcon

                        anchors.centerIn: parent
                        animate: true
                        text: device.modelData.connected ? "link_off" : "link"
                        color: device.connected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                        opacity: device.loading ? 0 : 1

                        Behavior on opacity {
                            Anim {}
                        }
                    }
                }
            }
        }
    }

    component ToggleButton: StyledRect {
        id: toggleBtn

        required property bool toggled
        property string icon
        property string label
        property string accent: "Secondary"

        function onClicked(): void {
        }

        Layout.preferredWidth: implicitWidth + (toggleStateLayer.pressed ? Config.appearance.padding.normal * 2 : toggled ? Config.appearance.padding.small * 2 : 0)
        implicitWidth: toggleBtnInner.implicitWidth + Config.appearance.padding.large * 2
        implicitHeight: toggleBtnIcon.implicitHeight + Config.appearance.padding.normal * 2

        radius: 0
        color: toggled ? Colours.palette[`m3${accent.toLowerCase()}`] : Colours.palette[`m3${accent.toLowerCase()}Container`]
        
        // Apply normal fillets for secondary elements
        filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.normal : 4

        StateLayer {
            id: toggleStateLayer

            color: toggleBtn.toggled ? Colours.palette[`m3on${toggleBtn.accent}`] : Colours.palette[`m3on${toggleBtn.accent}Container`]

            function onClicked(): void {
                toggleBtn.onClicked();
            }
        }

        RowLayout {
            id: toggleBtnInner

            anchors.centerIn: parent
            spacing: Config.appearance.spacing.normal

            MaterialIcon {
                id: toggleBtnIcon

                visible: !!text
                fill: toggleBtn.toggled ? 1 : 0
                text: toggleBtn.icon
                color: toggleBtn.toggled ? Colours.palette[`m3on${toggleBtn.accent}`] : Colours.palette[`m3on${toggleBtn.accent}Container`]
                font.pointSize: Config.appearance.font.size.large

                Behavior on fill {
                    Anim {}
                }
            }

            Loader {
                asynchronous: true
                active: !!toggleBtn.label
                visible: active

                sourceComponent: StyledText {
                    text: toggleBtn.label
                    color: toggleBtn.toggled ? Colours.palette[`m3on${toggleBtn.accent}`] : Colours.palette[`m3on${toggleBtn.accent}Container`]
                }
            }
        }

        Behavior on radius {
            Anim {
                duration: Config.appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Config.appearance.anim.curves.expressiveFastSpatial
            }
        }

        Behavior on Layout.preferredWidth {
            Anim {
                duration: Config.appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Config.appearance.anim.curves.expressiveFastSpatial
            }
        }
    }
}
