pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    // Expose the raw Hyprland singleton for direct access if needed
    readonly property var raw: Hyprland

    // Common properties mapped to match Niri (as best as possible) or just exposed
    readonly property var focusedWindow: Hyprland.activeWindow
    
    // Niri has 'capsLock', Hyprland might allow querying input devices or have a property
    // For now, hardcode or try to find a way. 
    // Quickshell Hyprland doesn't always expose keyboard state directly on the singleton.
    // I'll leave them false/default for now to prevent crashes.
    property bool capsLock: false 
    property bool numLock: false

    // Wrappers for commands
    function dispatch(cmd) {
        Hyprland.dispatch(cmd)
    }

    function toggleWindowFloating(window) {
        if (window) {
             // Hyprland uses address or regex
             dispatch(`togglefloating address:${window.address}`)
        } else {
             dispatch("togglefloating")
        }
    }
    
    // Add other methods used in Buttons.qml
    function closeFocusedWindow() {
        dispatch("killactive")
    }
}
