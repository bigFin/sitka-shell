import qs.services
import qs.components.controls
import QtQuick
import QtQuick.Layouts

// 3 Styled Radial buttons
RowLayout {

    property var client: Niri.focusedWindow

    Loader {
        active: Niri.focusedWindow && Niri.focusedWindow.is_floating
        asynchronous: true
        visible: active

        sourceComponent: StyledRadialButton {
            basecolor: Colours.palette.m3secondaryContainer
            onColor: Colours.palette.m3onSecondaryContainer
            disabled: !Niri.focusedWindow

            icon: "push_pin"
            function onClicked(): void {
                // TODO Add a way to pin in Niri.
                Niri.dispatch(`pin address:0x${root.client?.address}`);
            }
        }
    }

    StyledRadialButton {
        disabled: !Niri.focusedWindow
        basecolor: Niri.focusedWindow.is_floating ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer
        onColor: Niri.focusedWindow.is_floating ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer

        icon: Niri.focusedWindow.is_floating ? "grid_view" : "picture_in_picture"
        function onClicked(): void {
            Niri.toggleWindowFloating();
        }
    }
    StyledRadialButton {
        disabled: !Niri.focusedWindow
        basecolor: Colours.palette.m3tertiary
        onColor: Colours.palette.m3onTertiary

        icon: "fullscreen"
        function onClicked(): void {
            Niri.toggleMaximize();
        }
    }
    StyledRadialButton {
        disabled: !Niri.focusedWindow
        basecolor: Colours.palette.m3errorContainer
        onColor: Colours.palette.m3onErrorContainer
        icon: "close"
        function onClicked(): void {
            Niri.closeFocusedWindow();
        }
    }
}
