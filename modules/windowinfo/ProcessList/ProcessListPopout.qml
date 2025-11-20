import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets
import "../../../config"

Item {
    id: processListPanel

    visible: true

    Ref {
        service: SysMonitorService
    }

    Layout.alignment: Qt.AlignCenter

    implicitWidth: 600
    // implicitHeight: 600
    Layout.fillHeight: true
    // WlrLayershell.layer: WlrLayershell.Overlay
    // WlrLayershell.exclusiveZone: -1
    // WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    // color: "transparent"

    // anchors {
    //     top: true
    //     left: true
    //     right: true
    //     bottom: true
    // }

    // Loader is no longer needed for visibility toggling, so use content directly

    // antialiasing: true
    // smooth: true

    ColumnLayout {
        anchors.fill: parent
        spacing: Config.appearance.padding.normal

        SystemOverview {
            id: systemOverview
            // anchors.centerIn: parent
            // width: parent.width - Config.appearance.padding.normal * 2
            Layout.fillWidth: true
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Config.appearance.rounding.normal
            color: Colours.palette.m3surfaceContainer

            ProcessListView {
                anchors.fill: parent
                anchors.margins: Config.appearance.padding.small
                contextMenu: processContextMenu // keep if you want context menu
            }
        }
    }
    // }

    ProcessContextMenu {
        id: processContextMenu
    }
}
