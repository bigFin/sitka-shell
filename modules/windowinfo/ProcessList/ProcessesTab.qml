import QtQuick
import QtQuick.Layouts
import "../../../config"

ColumnLayout {
    id: processesTab
    anchors.fill: parent
    spacing: Config.appearance.padding.normal

    property var contextMenu: null

    SystemOverview {
        Layout.fillWidth: true
    }

    ProcessListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contextMenu: processesTab.contextMenu || localContextMenu
    }

    ProcessContextMenu {
        id: localContextMenu
    }
}
