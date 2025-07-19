import qs.services
import qs.config
import Quickshell
import QtQuick.Layouts

FloatingWindow {
    id: root

    property list<string> cwd: ["Home", "Downloads"]

    implicitWidth: 1000
    implicitHeight: 600
    color: Colours.palette.m3surface

    RowLayout {
        anchors.fill: parent
        anchors.margins: Appearance.padding.normal

        spacing: Appearance.spacing.normal

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            spacing: Appearance.spacing.small

            HeaderBar {
                Layout.fillWidth: true
                cwd: root.cwd
            }

            FolderContents {
                Layout.fillWidth: true
                Layout.fillHeight: true

                cwd: root.cwd
            }
        }
    }
}
