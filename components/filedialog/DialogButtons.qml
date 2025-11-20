import ".."
import qs.services
import "../../config"
import QtQuick.Layouts

StyledRect {
    id: root

    required property var dialog
    required property FolderContents folder

    implicitHeight: inner.implicitHeight + Config.appearance.padding.normal * 2

    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Config.appearance.padding.normal

        spacing: Config.appearance.spacing.small

        StyledText {
            text: qsTr("Filter:")
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: Config.appearance.spacing.normal

            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Config.appearance.rounding.small

            StyledText {
                anchors.fill: parent
                anchors.margins: Config.appearance.padding.normal

                text: `${root.dialog.filterLabel} (${root.dialog.filters.map(f => `*.${f}`).join(", ")})`
            }
        }

        StyledRect {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Config.appearance.rounding.small

            implicitWidth: cancelText.implicitWidth + Config.appearance.padding.normal * 2
            implicitHeight: cancelText.implicitHeight + Config.appearance.padding.normal * 2

            StateLayer {
                disabled: !root.dialog.selectionValid

                function onClicked(): void {
                    root.dialog.accepted(root.folder.currentItem.modelData.path);
                }
            }

            StyledText {
                id: selectText

                anchors.centerIn: parent
                anchors.margins: Config.appearance.padding.normal

                text: qsTr("Select")
                color: root.dialog.selectionValid ? Colours.palette.m3onSurface : Colours.palette.m3outline
            }
        }

        StyledRect {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Config.appearance.rounding.small

            implicitWidth: cancelText.implicitWidth + Config.appearance.padding.normal * 2
            implicitHeight: cancelText.implicitHeight + Config.appearance.padding.normal * 2

            StateLayer {
                function onClicked(): void {
                    root.dialog.rejected();
                }
            }

            StyledText {
                id: cancelText

                anchors.centerIn: parent
                anchors.margins: Config.appearance.padding.normal

                text: qsTr("Cancel")
            }
        }
    }
}
