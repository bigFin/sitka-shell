import qs.components
import qs.services
import "../../config"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var client: ActiveWindowModel.window

    // ***************************************************
    CollapsibleSection {
        id: moveWorkspaceDropdown // Give it an ID to reference its functions
        Layout.preferredWidth: 800
        title: qsTr("Move Window to Workspace")
        GridLayout {
            id: wsGrid
            columns: 5

            Repeater {
                model: WorkspaceModel.currentOutputWorkspaces

                Button {
                    required property var modelData
                    readonly property string wsId: String(modelData.id)
                    readonly property bool isCurrent: wsId === WorkspaceModel.focusedWorkspaceId

                    color: isCurrent ? Colours.tPalette.m3surfaceContainerHighest : Colours.palette.m3tertiaryContainer
                    onColor: isCurrent ? Colours.palette.m3onSurface : Colours.palette.m3onTertiaryContainer
                    text: modelData.name || "Workspace: " + modelData.idx
                    disabled: isCurrent

                    function onClicked(): void {
                        WMService.moveWindowToWorkspace(wsId);
                    }
                }
            }
        }
    }

    CollapsibleSection {
        id: utilities // Give it an ID to reference its functions
        title: qsTr("Window Utilities")
        backgroundMarginTop: 0
        expanded: true

        RowLayout {
            ColumnLayout {
                RowLayout {
                    // toggleFullscreen - Button 3
                    Button {
                        color: Colours.palette.m3secondaryContainer
                        onColor: Colours.palette.m3onSecondaryContainer
                        text: qsTr("Toggle Fullscreen")
                        icon: "fullscreen"
                        function onClicked(): void {
                            WMService.toggleFullscreen();
                        }
                    }

                    // toggleWindowedFullscreen - Button 4
                    Button {
                        color: Colours.palette.m3secondaryContainer
                        onColor: Colours.palette.m3onSecondaryContainer
                        icon: "disabled_visible"
                        text: qsTr("Toggle Fake Fullscreen")
                        function onClicked(): void {
                            WMService.toggleWindowedFullscreen();
                        }
                    }

                }
                Button {
                    color: Colours.palette.m3secondaryContainer
                    onColor: Colours.palette.m3onSecondaryContainer
                    text: qsTr("Center")
                    icon: "center_focus_strong"
                    function onClicked(): void {
                        WMService.centerWindow();
                    }
                }
                // Inhibit Shortcuts - Button 2
                Button {
                    color: Colours.palette.m3secondaryContainer
                    onColor: Colours.palette.m3onSecondaryContainer
                    icon: "disabled_visible"
                    text: qsTr("Inhibit Shortcuts")
                    function onClicked(): void {
                        WMService.keyboardShortcutsInhibitWindow();
                    }
                }
            }

            // Screenshot - Button 3

            Button {
                Layout.fillHeight: true
                color: Colours.palette.m3secondaryContainer
                onColor: Colours.palette.m3onSecondaryContainer
                text: qsTr("Screenshot Window")
                icon: "photo_camera"
                function onClicked(): void {
                    WMService.screenshotWindow();
                }
            }

        }
    }


    component Rect: StyledRect {
        radius: Config.appearance.rounding.small
        color: Colours.tPalette.m3surfaceContainerLow
    }

    // Your global Button component (if defined here)
    component Button: StyledRect {
        property color onColor: Colours.palette.m3onSurface
        property alias disabled: stateLayer.disabled
        property alias text: label.text
        property alias icon: icon.text

        function onClicked(): void {
        }

        Layout.fillWidth: true

        radius: Config.appearance.rounding.small

        implicitHeight: (icon.implicitHeight + Config.appearance.padding.small * 2)
        implicitWidth: (52 + Config.appearance.padding.small * 2)

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            // anchors.left: parent.left

            Item {
                Layout.fillWidth: true
            }
            MaterialIcon {
                id: icon
                color: parent.parent.onColor
                // font.pointSize: Config.appearance.font.size.large
                text: "radio_button_unchecked"
                font.pointSize: label.font.pointSize * 3.0

                // anchors.verticalCenter: parent.verticalCenter
                Layout.alignment: Qt.AlignVCenter

            }
            StyledText {
                id: label
                color: parent.parent.onColor
                font.pointSize: Config.appearance.font.size.small
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                Layout.preferredWidth: 90 // Adjust as needed for your layout
                // Optionally, set elide if text is too long
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        StateLayer {
            id: stateLayer
            color: parent.onColor
            function onClicked(): void {
                parent.onClicked();
            }
        }
    }
}
