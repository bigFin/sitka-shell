import qs.components
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    anchors.fill: parent
    anchors.margins: Appearance.padding.large * 2

    spacing: Appearance.spacing.large * 2

    RowLayout {
        spacing: Appearance.spacing.normal

        StyledRect {
            implicitWidth: prompt.implicitWidth + Appearance.padding.normal * 2
            implicitHeight: prompt.implicitHeight + Appearance.padding.normal * 2

            color: Colours.palette.m3primary
            radius: Appearance.rounding.small

            MonoText {
                id: prompt

                anchors.centerIn: parent
                text: ">"
                color: Colours.palette.m3onPrimary
            }
        }

        MonoText {
            text: "caelestiafetch.sh"
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.large * 2

        IconImage {
            Layout.fillHeight: true
            source: Quickshell.iconPath(SysInfo.logo)
            implicitSize: height
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.spacing.normal

            FetchText {
                text: qsTr("OS  : %1").arg(SysInfo.osPrettyName || SysInfo.osName)
            }

            FetchText {
                text: qsTr("WM  : %1").arg(SysInfo.wm)
            }

            FetchText {
                text: qsTr("USER: %1").arg(SysInfo.user)
            }

            FetchText {
                text: qsTr("SH  : %1").arg(SysInfo.shell)
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Appearance.spacing.large

        Repeater {
            model: 8

            StyledRect {
                required property int index

                implicitWidth: implicitHeight
                implicitHeight: Appearance.font.size.larger * 2
                color: Colours.palette[`term${index}`]
                radius: Appearance.rounding.small
            }
        }
    }

    component FetchText: MonoText {
        font.pointSize: Appearance.font.size.larger
        elide: Text.ElideRight
    }

    component MonoText: StyledText {
        font.family: Appearance.font.family.mono
    }
}
