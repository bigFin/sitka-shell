import qs.components
import qs.services
import qs.utils
import "../../../config"
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Item wrapper

    implicitWidth: ActiveWindowModel.hasWindow ? child.implicitWidth : -Config.appearance.padding.large * 2
    implicitHeight: child.implicitHeight

    ColumnLayout {
        id: child

        anchors.left: parent.left
        spacing: Config.appearance.spacing.normal

        RowLayout {
            id: detailsRow

            Layout.alignment: Qt.AlignLeft
            spacing: Config.appearance.spacing.normal

            IconImage {
                id: icon

                Layout.alignment: Qt.AlignVCenter
                implicitSize: details.implicitHeight
                source: Icons.getAppIcon(ActiveWindowModel.className ?? "", "image-missing")
            }

            ColumnLayout {
                id: details

                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: ActiveWindowModel.title ?? ""
                    font.pointSize: Config.appearance.font.size.normal
                    elide: Text.ElideRight
                    Layout.preferredWidth: 200
                }

                StyledText {
                    Layout.fillWidth: true
                    text: ActiveWindowModel.className ?? ""
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }
            }

            Item {
                implicitWidth: expandIcon.implicitHeight + Config.appearance.padding.small * 2
                implicitHeight: expandIcon.implicitHeight + Config.appearance.padding.small * 2

                Layout.alignment: Qt.AlignVCenter

                StateLayer {
                    radius: Config.appearance.rounding.normal

                    function onClicked(): void {
                        root.wrapper.detach("winfo");
                    }
                }

                MaterialIcon {
                    id: expandIcon

                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: font.pointSize * 0.05

                    text: "chevron_right"

                    font.pointSize: Config.appearance.font.size.large
                }
            }
        }

    }
}
