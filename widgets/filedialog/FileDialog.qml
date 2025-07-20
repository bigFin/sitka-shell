import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

FloatingWindow {
    id: root

    property list<string> cwd: ["Home"]

    signal accepted(path: string)

    implicitWidth: 1000
    implicitHeight: 600
    color: Colours.palette.m3surface

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
                Layout.fillWidth: true
                Layout.fillHeight: true
                dialog: root
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
