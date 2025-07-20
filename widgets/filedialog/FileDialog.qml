import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

FloatingWindow {
    id: root

    property list<string> cwd: ["Home"]
    property string filterLabel: "All files"
    property list<string> filters: ["*"]

    readonly property bool selectionValid: {
        const item = folderContents.currentItem;
        return item && !item.fileIsDir && (filters.includes("*") || filters.includes(item.fileSuffix));
    }

    signal accepted(path: string)
    signal rejected

    implicitWidth: 1000
    implicitHeight: 600
    color: Colours.palette.m3surface

    onAccepted: visible = false
    onRejected: visible = false

    RowLayout {
        anchors.fill: parent

        spacing: 0

        Sidebar {
            Layout.fillHeight: true
            dialog: root
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            spacing: 0

            HeaderBar {
                Layout.fillWidth: true
                dialog: root
            }

            FolderContents {
                id: folderContents

                Layout.fillWidth: true
                Layout.fillHeight: true
                dialog: root
            }

            DialogButtons {
                Layout.fillWidth: true
                dialog: root
                folder: folderContents
            }
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }
}
