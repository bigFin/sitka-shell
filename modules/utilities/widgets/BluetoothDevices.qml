pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import "../../../config"
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Config.appearance.spacing.small

    property bool expanded: false

    readonly property var adapter: Bluetooth.adapters.values.length > 0
        ? Bluetooth.adapters.values[0] : null
    readonly property bool powered: adapter?.powered ?? false
    readonly property var devices: Bluetooth.devices.values.filter(d => d.paired || d.connected)
    readonly property int connectedCount: devices.filter(d => d.connected).length

    // Header with toggle
    RowLayout {
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.small

        // Bluetooth icon
        MaterialIcon {
            text: root.powered ? "bluetooth" : "bluetooth_disabled"
            color: root.powered
                ? Colours.palette.m3primary
                : Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.size.large
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: qsTr("Bluetooth")
                font.weight: 600
                font.pointSize: Config.appearance.font.size.normal
                color: Colours.palette.m3onSurface
            }

            StyledText {
                text: {
                    if (!root.adapter) return qsTr("No adapter")
                    if (!root.powered) return qsTr("Disabled")
                    if (root.connectedCount > 0)
                        return qsTr("%1 connected").arg(root.connectedCount)
                    return qsTr("Enabled")
                }
                font.pointSize: Config.appearance.font.size.smaller
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        // Scan button
        StyledRect {
            visible: root.powered
            implicitWidth: implicitHeight
            implicitHeight: scanIcon.implicitHeight + Config.appearance.padding.small * 2
            radius: Config.appearance.rounding.small
            color: root.adapter?.discovering ? Colours.palette.m3primaryContainer : "transparent"

            MaterialIcon {
                id: scanIcon
                anchors.centerIn: parent
                text: "search"
                color: root.adapter?.discovering
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.size.normal

                RotationAnimation on rotation {
                    running: root.adapter?.discovering ?? false
                    from: 0
                    to: 360
                    duration: 2000
                    loops: Animation.Infinite
                }
            }

            StateLayer {
                radius: parent.radius
                function onClicked(): void {
                    if (root.adapter) {
                        root.adapter.discovering = !root.adapter.discovering
                    }
                }
            }
        }

        // Toggle switch
        StyledSwitch {
            visible: root.adapter !== null
            checked: root.powered
            onClicked: {
                if (root.adapter) {
                    root.adapter.powered = !root.powered
                }
            }
        }

        // Expand button
        StyledRect {
            visible: root.powered && root.devices.length > 0
            implicitWidth: implicitHeight
            implicitHeight: expandIcon.implicitHeight + Config.appearance.padding.small * 2
            radius: Config.appearance.rounding.small
            color: "transparent"

            MaterialIcon {
                id: expandIcon
                anchors.centerIn: parent
                text: root.expanded ? "expand_less" : "expand_more"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.size.normal
            }

            StateLayer {
                radius: parent.radius
                function onClicked(): void {
                    root.expanded = !root.expanded
                }
            }
        }
    }

    // Device list (when expanded)
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.expanded && root.powered
        spacing: 2

        Repeater {
            model: root.devices.sort((a, b) => {
                // Connected first, then by name
                if (a.connected !== b.connected) return b.connected - a.connected
                return (a.name || "").localeCompare(b.name || "")
            })

            DeviceItem {
                required property BluetoothDevice modelData

                Layout.fillWidth: true
                device: modelData
            }
        }

        // Empty state
        StyledText {
            visible: root.devices.length === 0
            text: root.adapter?.discovering
                ? qsTr("Scanning...")
                : qsTr("No paired devices")
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.size.small
        }
    }

    component DeviceItem: StyledRect {
        id: devItem

        required property BluetoothDevice device

        readonly property bool isConnected: device.connected

        implicitHeight: devRow.implicitHeight + Config.appearance.padding.small * 2
        radius: Config.appearance.rounding.small
        color: isConnected
            ? Colours.palette.m3primaryContainer
            : Colours.palette.m3surfaceContainerHigh

        RowLayout {
            id: devRow
            anchors.fill: parent
            anchors.margins: Config.appearance.padding.small
            spacing: Config.appearance.spacing.small

            // Device type icon
            MaterialIcon {
                text: {
                    const type = devItem.device.type
                    if (type === BluetoothDevice.Headphones || type === BluetoothDevice.Headset)
                        return "headphones"
                    if (type === BluetoothDevice.Keyboard)
                        return "keyboard"
                    if (type === BluetoothDevice.Mouse)
                        return "mouse"
                    if (type === BluetoothDevice.Phone)
                        return "smartphone"
                    if (type === BluetoothDevice.Computer)
                        return "computer"
                    if (type === BluetoothDevice.AudioVideo)
                        return "speaker"
                    return "bluetooth"
                }
                color: devItem.isConnected
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurface
                font.pointSize: Config.appearance.font.size.normal
            }

            // Device name
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: devItem.device.name || qsTr("Unknown Device")
                    font.pointSize: Config.appearance.font.size.small
                    font.weight: devItem.isConnected ? 600 : 400
                    color: devItem.isConnected
                        ? Colours.palette.m3onPrimaryContainer
                        : Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }

                StyledText {
                    visible: devItem.device.battery >= 0
                    text: qsTr("Battery: %1%").arg(devItem.device.battery)
                    font.pointSize: Config.appearance.font.size.smaller
                    color: devItem.isConnected
                        ? Colours.palette.m3onPrimaryContainer
                        : Colours.palette.m3onSurfaceVariant
                }
            }

            // Battery icon
            MaterialIcon {
                visible: devItem.device.battery >= 0
                text: {
                    const bat = devItem.device.battery
                    if (bat >= 90) return "battery_full"
                    if (bat >= 60) return "battery_5_bar"
                    if (bat >= 40) return "battery_3_bar"
                    if (bat >= 20) return "battery_2_bar"
                    return "battery_1_bar"
                }
                color: devItem.device.battery < 20
                    ? Colours.palette.m3error
                    : (devItem.isConnected
                        ? Colours.palette.m3onPrimaryContainer
                        : Colours.palette.m3onSurfaceVariant)
                font.pointSize: Config.appearance.font.size.small
            }

            // Connect/Disconnect button
            StyledRect {
                implicitWidth: connText.implicitWidth + Config.appearance.padding.normal * 2
                implicitHeight: connText.implicitHeight + Config.appearance.padding.small
                radius: Config.appearance.rounding.small
                color: devItem.isConnected
                    ? Colours.palette.m3error
                    : Colours.palette.m3primary

                StyledText {
                    id: connText
                    anchors.centerIn: parent
                    text: devItem.isConnected ? qsTr("Disconnect") : qsTr("Connect")
                    font.pointSize: Config.appearance.font.size.smaller
                    color: devItem.isConnected
                        ? Colours.palette.m3onError
                        : Colours.palette.m3onPrimary
                }

                StateLayer {
                    radius: parent.radius
                    color: devItem.isConnected
                        ? Colours.palette.m3onError
                        : Colours.palette.m3onPrimary
                    function onClicked(): void {
                        if (devItem.isConnected)
                            devItem.device.disconnect()
                        else
                            devItem.device.connect()
                    }
                }
            }
        }
    }
}
