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

    StyledText {
        text: qsTr("Quick Toggles")
        font.weight: 600
        font.pointSize: Config.appearance.font.size.normal
        color: Colours.palette.m3onSurface
    }

    // Toggle grid - 2 columns
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: Config.appearance.spacing.small
        columnSpacing: Config.appearance.spacing.small

        // WiFi toggle
        QuickToggle {
            Layout.fillWidth: true
            label: qsTr("WiFi")
            icon: Network.wifiEnabled ? "wifi" : "wifi_off"
            active: Network.wifiEnabled
            subtitle: Network.active?.ssid ?? (Network.wifiEnabled ? qsTr("Not connected") : qsTr("Disabled"))
            onClicked: Network.toggleWifi()
        }

        // Bluetooth toggle
        QuickToggle {
            readonly property var btAdapter: Bluetooth.adapters.values.length > 0 ? Bluetooth.adapters.values[0] : null
            readonly property bool btPowered: btAdapter?.powered ?? false

            Layout.fillWidth: true
            label: qsTr("Bluetooth")
            icon: btPowered ? "bluetooth" : "bluetooth_disabled"
            active: btPowered
            subtitle: {
                if (!btAdapter) return qsTr("No adapter")
                if (!btPowered) return qsTr("Disabled")
                const connected = Bluetooth.devices.values.filter(d => d.connected).length
                return connected > 0 ? qsTr("%1 connected").arg(connected) : qsTr("Enabled")
            }
            onClicked: {
                if (btAdapter)
                    btAdapter.powered = !btPowered
            }
        }

        // Idle Inhibitor toggle
        QuickToggle {
            Layout.fillWidth: true
            label: qsTr("Caffeine")
            icon: IdleInhibitor.enabled ? "coffee" : "coffee_maker"
            active: IdleInhibitor.enabled
            subtitle: IdleInhibitor.enabled ? qsTr("Screen stays on") : qsTr("Off")
            onClicked: IdleInhibitor.enabled = !IdleInhibitor.enabled
        }

        // Screen Recorder toggle
        QuickToggle {
            Layout.fillWidth: true
            label: qsTr("Record")
            icon: Recorder.running ? "stop_circle" : "screen_record"
            active: Recorder.running
            subtitle: Recorder.running ? Recorder.formatElapsed() : qsTr("Off")
            onClicked: {
                if (Recorder.running)
                    Recorder.stop()
                else
                    Recorder.start()
            }
        }

        // Do Not Disturb toggle
        QuickToggle {
            Layout.fillWidth: true
            label: qsTr("DND")
            icon: Notifs.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
            active: Notifs.dnd
            subtitle: Notifs.dnd ? qsTr("Notifications muted") : qsTr("Off")
            onClicked: Notifs.dnd = !Notifs.dnd
        }

        // Mute toggle
        QuickToggle {
            Layout.fillWidth: true
            label: qsTr("Mute")
            icon: Audio.muted ? "volume_off" : "volume_up"
            active: Audio.muted
            subtitle: Audio.muted ? qsTr("Audio muted") : `${Math.round(Audio.volume * 100)}%`
            onClicked: {
                if (Audio.sink?.audio)
                    Audio.sink.audio.muted = !Audio.muted
            }
        }
    }

    component QuickToggle: StyledRect {
        id: toggle

        required property string label
        required property string icon
        required property bool active
        property string subtitle: ""

        signal clicked()

        implicitHeight: toggleContent.implicitHeight + Config.appearance.padding.normal * 2
        radius: Config.appearance.rounding.normal
        color: toggle.active
            ? Colours.palette.m3primaryContainer
            : Colours.palette.m3surfaceContainerHigh

        StateLayer {
            radius: parent.radius
            color: toggle.active
                ? Colours.palette.m3onPrimaryContainer
                : Colours.palette.m3onSurface
            function onClicked(): void {
                toggle.clicked()
            }
        }

        RowLayout {
            id: toggleContent
            anchors.fill: parent
            anchors.margins: Config.appearance.padding.normal
            spacing: Config.appearance.spacing.small

            MaterialIcon {
                text: toggle.icon
                color: toggle.active
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurface
                font.pointSize: Config.appearance.font.size.large
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: toggle.label
                    font.weight: 500
                    font.pointSize: Config.appearance.font.size.small
                    color: toggle.active
                        ? Colours.palette.m3onPrimaryContainer
                        : Colours.palette.m3onSurface
                }

                StyledText {
                    visible: toggle.subtitle.length > 0
                    text: toggle.subtitle
                    font.pointSize: Config.appearance.font.size.smaller
                    color: toggle.active
                        ? Colours.palette.m3onPrimaryContainer
                        : Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }
}
