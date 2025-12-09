pragma ComponentBehavior: Bound

import qs.components
import qs.services
import "../../config"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var client: null
    property var wrapper: null // Fix undefined reference

    Connections {
        target: WMService // Listen to the WMService singleton
        function onFocusedWindowChanged(): void {
            root.client = WMService.focusedWindow || null;
        }
    }

    Component.onCompleted: {
        root.client = WMService.focusedWindow;
    }

    anchors.fill: parent
    spacing: Config.appearance.spacing.small

    // ***************************************************
    // Using the new CollapsibleSection component
    CollapsibleSection {
        id: moveWorkspaceDropdown // Give it an ID to reference its functions
        title: qsTr("Move to workspace")
        // The content for this dropdown is placed directly inside.
        // It automatically forms a Component and is assigned to contentComponent.
        GridLayout {
            id: wsGrid

            // rowSpacing: Config.appearance.spacing.smaller
            // columnSpacing: Config.appearance.spacing.smaller
            columns: 5

            Repeater {
                model: WMService.getWorkspaceCount()

                Button {
                    required property int index
                    readonly property int wsId: Math.floor((WMService.focusedWorkspaceIndex) / 10) * 10 + index + 1
                    readonly property bool isCurrent: (wsId - 1) % 10 === WMService.focusedWorkspaceIndex

                    color: isCurrent ? Colours.tPalette.m3surfaceContainerHighest : Colours.palette.m3tertiaryContainer
                    onColor: isCurrent ? Colours.palette.m3onSurface : Colours.palette.m3onTertiaryContainer
                    text: (WMService.currentOutputWorkspaces && WMService.currentOutputWorkspaces[wsId - 1] ? WMService.currentOutputWorkspaces[wsId - 1].name : "") || wsId
                    disabled: isCurrent

                    function onClicked(): void {
                        WMService.moveWindowToWorkspace(wsId);
                    // Call the collapse function on the CollapsibleSection instance
                    // moveWorkspaceDropdown.collapse();
                    }
                }
            }
        }
    }

    CollapsibleSection {
        id: utilities // Give it an ID to reference its functions
        title: qsTr("Utilities")
        backgroundMarginTop: 0

        //  toggleWindowOpacity
        //  expandColumnToAvailable
        //  centerWindow
        //  screenshotWindow
        //  keyboardShortcutsInhibitWindow
        //  toggleWindowedFullscreen
        //  toggleFullscreen
        //  toggleMaximize
        RowLayout {
            Layout.fillWidth: true
            // Layout.leftMargin: Config.appearance.padding.large
            // Layout.rightMargin: Config.appearance.padding.large

            Button {
                color: Colours.palette.m3secondaryContainer
                onColor: Colours.palette.m3onSecondaryContainer
                text: qsTr("Center")
                icon: "center_focus_strong"

                function onClicked(): void {
                    WMService.centerWindow();
                }
            }
            Button {
                color: Colours.palette.m3secondaryContainer
                onColor: Colours.palette.m3onSecondaryContainer
                text: qsTr("Screenshot")
                icon: "camera"
                // Layout.fillWidth: false

                function onClicked(): void {
                    WMService.screenshotWindow();
                }
            }
            Button {
                color: Colours.palette.m3secondaryContainer
                onColor: Colours.palette.m3onSecondaryContainer
                icon: "disabled_visible"
                text: qsTr("Inhibit Shortcuts")
                // Layout.fillWidth: false
                function onClicked(): void {
                    WMService.keyboardShortcutsInhibitWindow();
                }
            }
        }
    }

    // ***************************************************

    Loader {

        active: wrapper?.isDetached ?? true // Default to true if wrapper null (e.g. testing)
        asynchronous: true
        Layout.fillWidth: active
        visible: active
        Layout.leftMargin: Config.appearance.padding.large
        Layout.rightMargin: Config.appearance.padding.large
        Layout.bottomMargin: Config.appearance.padding.large

        sourceComponent: RowLayout {
            // Layout.fillWidth: true

            readonly property bool isFloating: WMService.focusedWindow?.is_floating || WMService.focusedWindow?.floating || false
            
            Button {
                color: isFloating ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer
                onColor: isFloating ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                text: root.client?.is_floating ? qsTr("Tile") : qsTr("Float")
                icon: root.client?.is_floating ? "grid_view" : "picture_in_picture"

                function onClicked(): void {
                    WMService.toggleWindowFloating();
                }
            }

            Loader {
                active: isFloating
                asynchronous: true
                Layout.fillWidth: active
                visible: active
                // Layout.leftMargin: active ? 0 : -parent.spacing * 2
                // Layout.rightMargin: active ? 0 : -parent.spacing * 2

                sourceComponent: Button {
                    color: Colours.palette.m3secondaryContainer
                    onColor: Colours.palette.m3onSecondaryContainer
                    text: root.client?.pinned ? qsTr("Unpin") : qsTr("Pin")
                    icon: root.client?.pinned ? "push_pin" : "push_pin"

                    // TODO Add a way to pin stuff in Niri

                    function onClicked(): void {
                        // Use address if available
                        const addr = root.client?.address
                        if (addr) WMService.dispatch(`pin address:0x${addr}`);
                    }
                }
            }

            Button {
                color: Colours.palette.m3secondaryContainer
                onColor: Colours.palette.m3onSecondaryContainer
                icon: "fullscreen"
                text: qsTr("Fullscreen")

                function onClicked(): void {
                    WMService.toggleMaximize();
                }
            }

            Button {
                color: Colours.palette.m3errorContainer
                onColor: Colours.palette.m3onErrorContainer
                text: qsTr("Kill")
                icon: "close"

                function onClicked(): void {
                    WMService.closeFocusedWindow();
                }
            }
        }
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

        MaterialIcon {
            id: icon
            color: parent.onColor
            font.pointSize: Config.appearance.font.size.large
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            opacity: icon.text ? !stateLayer.containsMouse : true
            Behavior on opacity {
                PropertyAnimation {
                    property: "opacity"
                    duration: Config.appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.appearance.anim.curves.standard
                }
            }
        }

        StyledText {
            id: label
            color: parent.onColor
            font.pointSize: Config.appearance.font.size.small
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            opacity: icon.text ? stateLayer.containsMouse : true
            Behavior on opacity {
                PropertyAnimation {
                    property: "opacity"
                    duration: Config.appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.appearance.anim.curves.standard
                }
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
