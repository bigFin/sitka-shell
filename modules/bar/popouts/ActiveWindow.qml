import qs.widgets
import qs.services
import qs.utils
import qs.config
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
// import qs.widgets
import qs.modules.windowinfo // TODO Niri for details.

Item {
    id: root

    required property Item wrapper

    implicitWidth: Niri.focusedWindowTitle /*Niri.activeToplevel*/ ? child.implicitWidth : -Appearance.padding.large * 2
    implicitHeight: child.implicitHeight

    Column {
        id: child

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        RowLayout {
            id: detailsRow

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.normal

            IconImage {
                id: icon

                Layout.alignment: Qt.AlignVCenter
                implicitSize: details.implicitHeight
                source: Icons.getAppIcon(Niri.focusedWindowClass ?? "", "image-missing")
            }

            ColumnLayout {
                id: details

                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: Niri.focusedWindowTitle ?? ""
                    font.pointSize: Appearance.font.size.normal
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Niri.focusedWindowClass ?? ""
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }
            }

            Item {
                implicitWidth: expandIcon.implicitHeight + Appearance.padding.small * 2
                implicitHeight: expandIcon.implicitHeight + Appearance.padding.small * 2

                Layout.alignment: Qt.AlignVCenter

                StateLayer {
                    radius: Appearance.rounding.normal

                    function onClicked(): void {
                        root.wrapper.detach("winfo");
                    }
                }

                MaterialIcon {
                    id: expandIcon

                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: font.pointSize * 0.05

                    text: "chevron_right"

                    font.pointSize: Appearance.font.size.large
                }
            }
        }


        StyledRect {
            // Layout.fillWidth: true
            // Layout.fillHeight: true
            // clip: true

            Layout.preferredHeight: buttons.implicitHeight
            height : 250

            width: Config.bar.sizes.windowPreviewSize
            // color: Colours.palette.m3surfaceContainer
            radius: Appearance.rounding.normal

            Flickable {
                id: flick
                anchors.fill: parent
                contentHeight: buttons.implicitHeight

                interactive: true
                clip: true

                Buttons {
                    id: buttons
                    // Your buttons content here
                }

                ScrollBar.vertical: StyledScrollBar {}
            }


        }

        // ClippingWrapperRectangle {
        //     color: "transparent"
        //     radius: Appearance.rounding.small
        //
        //     ScreencopyView {
        //         id: preview
        //
        //         // captureSource: Niri.activeToplevel ?? null
        //         captureSource: Quickshell.Wayland.findClientByPid(Niri.focusedWindow.pid) ?? null
        //         live: visible
        //
        //         constraintSize.width: Config.bar.sizes.windowPreviewSize
        //         constraintSize.height: Config.bar.sizes.windowPreviewSize
        //     }
        // }
    }
}
