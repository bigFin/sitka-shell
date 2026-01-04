pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import "../../../config"
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Config.appearance.spacing.small

    property bool expanded: false

    // Header with toggle
    RowLayout {
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.small

        // WiFi icon and status
        MaterialIcon {
            text: Network.wifiEnabled ? "wifi" : "wifi_off"
            color: Network.wifiEnabled
                ? Colours.palette.m3primary
                : Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.size.large
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: qsTr("WiFi")
                font.weight: 600
                font.pointSize: Config.appearance.font.size.normal
                color: Colours.palette.m3onSurface
            }

            StyledText {
                text: Network.active?.ssid ?? (Network.wifiEnabled ? qsTr("Not connected") : qsTr("Disabled"))
                font.pointSize: Config.appearance.font.size.smaller
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        // Scan button
        StyledRect {
            visible: Network.wifiEnabled
            implicitWidth: implicitHeight
            implicitHeight: scanIcon.implicitHeight + Config.appearance.padding.small * 2
            radius: Config.appearance.rounding.small
            color: "transparent"

            MaterialIcon {
                id: scanIcon
                anchors.centerIn: parent
                text: "refresh"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.size.normal

                RotationAnimation on rotation {
                    running: Network.scanning
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }

            StateLayer {
                radius: parent.radius
                function onClicked(): void {
                    Network.rescanWifi()
                }
            }
        }

        // Toggle switch
        StyledSwitch {
            checked: Network.wifiEnabled
            onClicked: Network.toggleWifi()
        }

        // Expand button
        StyledRect {
            visible: Network.wifiEnabled
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

    // Network list (when expanded)
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.expanded && Network.wifiEnabled
        spacing: 2

        Repeater {
            model: Network.networks.sort((a, b) => {
                // Active first, then by signal strength
                if (a.active !== b.active) return b.active - a.active
                return b.strength - a.strength
            }).slice(0, 10) // Limit to 10 networks

            NetworkItem {
                required property var modelData

                Layout.fillWidth: true
                ssid: modelData.ssid
                strength: modelData.strength
                isSecure: modelData.isSecure
                isActive: modelData.active
                onConnect: Network.connectToNetwork(modelData.ssid, "")
                onDisconnect: Network.disconnectFromNetwork()
            }
        }

        // Empty state
        StyledText {
            visible: Network.networks.length === 0
            text: Network.scanning ? qsTr("Scanning...") : qsTr("No networks found")
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.size.small
        }
    }

    component NetworkItem: StyledRect {
        id: netItem

        required property string ssid
        required property int strength
        required property bool isSecure
        required property bool isActive

        signal connect()
        signal disconnect()

        implicitHeight: netRow.implicitHeight + Config.appearance.padding.small * 2
        radius: Config.appearance.rounding.small
        color: isActive
            ? Colours.palette.m3primaryContainer
            : Colours.palette.m3surfaceContainerHigh

        RowLayout {
            id: netRow
            anchors.fill: parent
            anchors.margins: Config.appearance.padding.small
            spacing: Config.appearance.spacing.small

            // Signal strength icon
            MaterialIcon {
                text: {
                    if (netItem.strength >= 75) return "signal_wifi_4_bar"
                    if (netItem.strength >= 50) return "network_wifi_3_bar"
                    if (netItem.strength >= 25) return "network_wifi_2_bar"
                    return "network_wifi_1_bar"
                }
                color: netItem.isActive
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurface
                font.pointSize: Config.appearance.font.size.normal
            }

            // SSID
            StyledText {
                Layout.fillWidth: true
                text: netItem.ssid
                font.pointSize: Config.appearance.font.size.small
                font.weight: netItem.isActive ? 600 : 400
                color: netItem.isActive
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurface
                elide: Text.ElideRight
            }

            // Security indicator
            MaterialIcon {
                visible: netItem.isSecure
                text: "lock"
                color: netItem.isActive
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.size.small
            }

            // Connect/Disconnect button
            StyledRect {
                implicitWidth: connText.implicitWidth + Config.appearance.padding.normal * 2
                implicitHeight: connText.implicitHeight + Config.appearance.padding.small
                radius: Config.appearance.rounding.small
                color: netItem.isActive
                    ? Colours.palette.m3error
                    : Colours.palette.m3primary

                StyledText {
                    id: connText
                    anchors.centerIn: parent
                    text: netItem.isActive ? qsTr("Disconnect") : qsTr("Connect")
                    font.pointSize: Config.appearance.font.size.smaller
                    color: netItem.isActive
                        ? Colours.palette.m3onError
                        : Colours.palette.m3onPrimary
                }

                StateLayer {
                    radius: parent.radius
                    color: netItem.isActive
                        ? Colours.palette.m3onError
                        : Colours.palette.m3onPrimary
                    function onClicked(): void {
                        if (netItem.isActive)
                            netItem.disconnect()
                        else
                            netItem.connect()
                    }
                }
            }
        }
    }
}
