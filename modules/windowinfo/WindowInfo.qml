import qs.components
import qs.services
import "../../config"
import Quickshell
// import Quickshell.Hyprland // Removed strict dependency
import QtQuick
import QtQuick.Layouts
import "ProcessList"

Item {
    id: root

    required property ShellScreen screen
    property var client: null // Was HyprlandToplevel
    property var wrapper: null

    implicitWidth: child.implicitWidth
    implicitHeight: screen.height * Config.winfo.sizes.heightMult

    RowLayout {
        id: child

        anchors.fill: parent
        anchors.margins: Config.appearance.padding.large

        spacing: Config.appearance.spacing.normal

        // Preview {
        //     screen: root.screen
        //     client: root.client
        // }

        // ProcessListPopout {
        //     id: processListPopout
        // }

        ProcessListModal {
            id: processListModal
        }

        // ProcessListModal {

        // }

        ColumnLayout {
            spacing: Config.appearance.spacing.normal

            Layout.preferredWidth: Config.winfo.sizes.detailsWidth
            Layout.fillHeight: true

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true

                color: Colours.tPalette.m3surfaceContainer
                radius: Config.appearance.rounding.normal

                Details {
                    client: root.client
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: buttons.implicitHeight

                color: Colours.tPalette.m3surfaceContainer
                radius: Config.appearance.rounding.normal

                Buttons {
                    id: buttons

                    client: root.client
                    wrapper: root.wrapper
                }
            }
        }
    }
}
