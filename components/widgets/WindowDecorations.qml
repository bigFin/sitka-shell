pragma ComponentBehavior: Bound

import qs.services
import qs.components.controls
import QtQuick
import QtQuick.Layouts
import "../../config"

// 3 Styled Radial buttons
RowLayout {
    id: root
    property var client: WMService.focusedWindow
    property int implicitSize: Config.appearance.font.size.normal
    
    readonly property bool isFloating: client?.is_floating || client?.floating || false
    // If client is the focused window, it's focused. Otherwise check property.
    readonly property bool isFocused: (client === WMService.focusedWindow) || client?.is_focused || false

    spacing: Config.appearance.padding.small / 2

    Loader {
        active: root.isFloating
        asynchronous: true
        visible: active

        sourceComponent: StyledRadialButton {
            basecolor: Colours.palette.m3secondaryContainer
            color: Colours.palette.m3onSecondaryContainer
            disabled: !root.client

            implicitSize: root.implicitSize

            icon: "push_pin"
            function onClicked(): void {
                // TODO Add a way to pin in Niri.
                const addr = root.client?.address || root.client?.id
                WMService.dispatch(`pin address:0x${addr}`);
            }
        }
    }

    StyledRadialButton {
        disabled: !root.client
        basecolor: root.isFloating ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer
        onColor: root.isFloating ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer

        implicitSize: root.implicitSize

        icon: root.isFloating ? "grid_view" : "picture_in_picture"
        function onClicked(): void {
            // console.log("Toggling floating for", root.client?.id);
            WMService.toggleWindowFloating(root.client);
        }
    }

    Loader {
        active: root.isFocused
        asynchronous: true
        visible: active

        sourceComponent: StyledRadialButton {
            disabled: !root.client
            basecolor: Colours.palette.m3tertiary
            onColor: Colours.palette.m3onTertiary

            implicitSize: root.implicitSize

            icon: "fullscreen"
            function onClicked(): void {
                WMService.toggleMaximize();
            }
        }
    }

    StyledRadialButton {
        disabled: !root.client
        basecolor: Colours.palette.m3errorContainer
        onColor: Colours.palette.m3onErrorContainer
        icon: "close"

        implicitSize: root.implicitSize

        function onClicked(): void {
            WMService.closeWindow(root.client);
        }
    }
}
