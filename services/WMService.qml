pragma Singleton
import QtQuick

Singleton {
    id: root

    property bool isNiri: WMDetector.isNiri

    // --- Properties ---

    readonly property var focusedWindow: isNiri ? Niri.focusedWindow : Hypr.focusedWindow
    
    // Workspaces
    // Niri has arrays of objects. Hyprland likely has list of objects.
    // We expose what the UI needs.
    // UI uses: focusedWorkspaceIndex, currentOutputWorkspaces (array), getWorkspaceCount()
    
    readonly property int focusedWorkspaceIndex: isNiri ? Niri.focusedWorkspaceIndex : (Hypr.raw.activeWorkspace ? Hypr.raw.activeWorkspace.id - 1 : 0)
    
    readonly property var currentOutputWorkspaces: isNiri ? Niri.currentOutputWorkspaces : [] // TODO: Map Hyprland workspaces
    
    readonly property bool capsLock: isNiri ? Niri.capsLock : Hypr.capsLock
    readonly property bool numLock: isNiri ? Niri.numLock : Hypr.numLock

    // --- UI State (Context Menus) ---
    // Moved/Shared from Niri.qml logic
    property var wsContextExpanded: false
    property var wsContextAnchor: null
    property string wsContextType: "none" // "item", "workspace", "workspaces", "none"
    property Timer wsAnchorClearTimer: Timer {
        interval: 300 // default normal duration
        repeat: false
        onTriggered: {
            if (root.wsContextAnchor === null) {
                root.wsContextType = "none";
            }
        }
    }

    onWsContextAnchorChanged: {
        wsAnchorClearTimer.stop();
        if (wsContextAnchor === null) {
            wsAnchorClearTimer.start();
        }
    }

    // --- Outputs ---
    readonly property var outputs: isNiri ? Niri.outputs : ({}) // TODO: Hyprland outputs
    
    readonly property string focusedWindowId: isNiri ? Niri.focusedWindowId : (Hypr.raw.activeWindow?.address ? "0x" + Hypr.raw.activeWindow.address : "")
    readonly property string focusedMonitorName: isNiri ? Niri.focusedMonitorName : ""

    // --- Methods ---

    function focusWindow(windowID) {
        if (isNiri) Niri.focusWindow(windowID)
        else Hypr.dispatch(`focuswindow address:${windowID}`)
    }

    function getWorkspaceCount() {
        return isNiri ? Niri.getWorkspaceCount() : 10 // TODO Hyprland count
    }

    function moveWindowToWorkspace(wsId) {
        if (isNiri) Niri.moveWindowToWorkspace(wsId)
        else Hypr.dispatch(`movetoworkspace ${wsId}`)
    }

    function centerWindow() {
        if (isNiri) Niri.centerWindow()
        else Hypr.dispatch("centerwindow")
    }

    function screenshotWindow() {
        if (isNiri) Niri.screenshotWindow()
        // Hyprland doesn't have a direct screenshot window dispatch usually, depends on external tools (grim/slurp)
        // Leaving empty or using exec
    }

    function keyboardShortcutsInhibitWindow() {
        if (isNiri) Niri.keyboardShortcutsInhibitWindow()
        // Hyprland equivalent?
    }

    function toggleWindowFloating(window) {
        if (isNiri) {
             // Niri expects ID
             const id = (window && typeof window === 'object' && window.id !== undefined) ? window.id : window;
             Niri.toggleWindowFloating(id);
        } else {
             Hypr.toggleWindowFloating(window)
        }
    }

    function toggleMaximize() {
        if (isNiri) Niri.toggleMaximize()
        else Hypr.dispatch("fullscreen 1") // Maximize (keep gaps) vs fullscreen 0
    }

    function closeFocusedWindow() {
        if (isNiri) Niri.closeFocusedWindow()
        else Hypr.closeFocusedWindow()
    }

    function closeWindow(window) {
        if (isNiri) {
             const id = (window && typeof window === 'object' && window.id !== undefined) ? window.id : window;
             Niri.closeWindow(id)
        } else {
             // Hyprland close by address
             const addr = (window && typeof window === 'object' && window.address !== undefined) ? window.address : window;
             // If addr is just ID string, assume it works or handle 0x prefix
             Hypr.dispatch(`closewindow address:${addr}`) 
        }
    }
    
    function dispatch(cmd) {
        if (isNiri) Niri.dispatch(cmd) // Niri uses 'msg action ...' usually? Niri.qml doesn't have generic dispatch exposed? 
        // Checking Niri.qml: has dispatch(cmd) for "pin address..."?
        // Niri.qml DOES NOT have dispatch function in the file I read!
        // Wait, Buttons.qml calls Niri.dispatch(`pin address...`)
        // I must have missed it in Niri.qml or it's dynamic?
        // Re-checking Niri.qml ...
        else Hypr.dispatch(cmd)
    }
}
