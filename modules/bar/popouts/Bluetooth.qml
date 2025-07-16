import qs.widgets
import qs.services
import qs.config
import QtQuick

Column {
    id: root

    spacing: Appearance.spacing.normal

    StyledText {
        text: qsTr("Bluetooth %1").arg(Bluetooth.powered ? "enabled" : "disabled")
    }

    StyledText {
        text: Bluetooth.devices.some(d => d.connected) ? qsTr("Connected to: %1").arg(Bluetooth.devices.filter(d => d.connected).map(d => d.alias).join(", ")) : qsTr("No devices connected")
    }
}
