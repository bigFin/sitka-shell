import qs.components
import qs.services
import "../../../config"
import QtQuick.Layouts

ColumnLayout {
    spacing: Config.appearance.spacing.small

    StyledText {
        text: qsTr("Capslock: %1").arg(WMService.capsLock ? "Enabled" : "Disabled")
    }

    StyledText {
        text: qsTr("Numlock: %1").arg(WMService.numLock ? "Enabled" : "Disabled")
    }
}
