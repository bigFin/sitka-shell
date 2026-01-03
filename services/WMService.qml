pragma Singleton
import QtQuick
import Quickshell
import "."

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
    
    readonly property string focusedWindowClass: isNiri ? Niri.focusedWindowClass : (Hypr.raw.activeWindow?.class ?? "")
    readonly property string focusedWindowTitle: isNiri ? Niri.focusedWindowTitle : (Hypr.raw.activeWindow?.title ?? "")
    
    readonly property string kbLayout: isNiri ? Niri.kbLayout : "us" // TODO Hyprland layout
    readonly property string kbLayoutFull: isNiri ? Niri.kbLayouts : "us" // Full layout string
    readonly property string defaultKbLayout: isNiri ? Niri.defaultKbLayout : "us"

    // Additional Niri properties for UI compatibility
    readonly property var allWorkspaces: isNiri ? Niri.allWorkspaces : [] // TODO: Hyprland workspaces mapping
    readonly property string focusedWorkspaceId: isNiri ? Niri.focusedWorkspaceId : ""
    readonly property var workspaceHasWindows: isNiri ? Niri.workspaceHasWindows : ({})
    readonly property var lastFocusedWindow: isNiri ? Niri.lastFocusedWindow : null

    // --- Methods ---

    function getActiveWorkspaceWindows() {
        if (isNiri) return Niri.getActiveWorkspaceWindows()
        // TODO Hyprland implementation: filter clients by active workspace
        return [] 
    }

    function switchToWorkspaceUpDown(direction) {
        if (isNiri) Niri.switchToWorkspaceUpDown(direction)
        else {
             // Hyprland doesn't have direct up/down workspace switch relative to grid usually without plugins
             // Assuming numeric workspace switch for now or generic dispatch
             if (direction === "up") Hypr.dispatch("workspace +1")
             else Hypr.dispatch("workspace -1")
        }
    }

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
        if (isNiri) Niri.dispatch(cmd)
        else Hypr.dispatch(cmd)
    }

    // Additional methods for UI compatibility
    function getWindowsByWorkspaceId(wsId) {
        if (isNiri) return Niri.getWindowsByWorkspaceId(wsId)
        // TODO: Hyprland implementation
        return []
    }

    function getWindowsByWorkspaceIndex(index) {
        if (isNiri) return Niri.getWindowsByWorkspaceIndex(index)
        // TODO: Hyprland implementation
        return []
    }

    function groupWindowsByLayoutAndId(windows) {
        if (isNiri) return Niri.groupWindowsByLayoutAndId(windows)
        // TODO: Hyprland fallback - basic grouping by app
        return []
    }

    function groupWindowsByApp(windows) {
        if (isNiri) return Niri.groupWindowsByApp(windows)
        // TODO: Hyprland fallback
        return []
    }

    function switchToWorkspace(workspaceId) {
        if (isNiri) return Niri.switchToWorkspace(workspaceId)
        // Hyprland: assume workspaceId is numeric
        Hypr.dispatch(`workspace ${workspaceId}`)
    }

    function switchToWorkspaceByIndex(index) {
        if (isNiri) return Niri.switchToWorkspaceByIndex(index)
        // Hyprland: workspace id is index + 1
        Hypr.dispatch(`workspace ${index + 1}`)
    }

    function moveGroupColumnsSequential(curWindowId, windowIds, targetIndex, delayMs) {
        if (isNiri) return Niri.moveGroupColumnsSequential(curWindowId, windowIds, targetIndex, delayMs)
        // TODO: Hyprland implementation - not supported
    }

    function moveColumnToIndexAfterFocus(windowId, index, delayMs) {
        if (isNiri) return Niri.moveColumnToIndexAfterFocus(windowId, index, delayMs)
        // TODO: Hyprland - not directly supported
    }

    function getWorkspaceNameByIndex(index) {
        if (isNiri) return Niri.getWorkspaceNameByIndex(index)
        // Hyprland: no custom names, return index + 1
        return (index + 1).toString()
    }

    function getWorkspaceNameById(id) {
        if (isNiri) return Niri.getWorkspaceNameById(id)
        // Hyprland: assume id is numeric
        return id.toString()
    }

    function cleanWindowTitle(title) {
        if (isNiri) return Niri.cleanWindowTitle(title)
        // Basic cleanup
        return title ? title.replace(/^[^\x20-\x7E]+/, "") : title
    }

    function getWindowsInScreen(screenX, screenY, screenWidth, screenHeight, windowBorder, padding) {
        if (isNiri) return Niri.getWindowsInScreen(screenX, screenY, screenWidth, screenHeight, windowBorder, padding)
        // TODO: Hyprland implementation
        return []
    }

    function toggleFullscreen() {
        if (isNiri) return Niri.toggleFullscreen()
        Hypr.dispatch("fullscreen 0") // Toggle fullscreen
    }

    function toggleWindowedFullscreen() {
        if (isNiri) return Niri.toggleWindowedFullscreen()
        // Hyprland doesn't have windowed fullscreen, use regular fullscreen
        Hypr.dispatch("fullscreen 0")
    }

    function expandColumnToAvailable() {
        if (isNiri) return Niri.expandColumnToAvailable()
        // TODO: Hyprland equivalent?
    }

    function toggleWindowOpacity() {
        if (isNiri) return Niri.toggleWindowOpacity()
        // TODO: Hyprland opacity toggle
    }

    // ===== NEW ARCHITECTURE: WindowStore Accessors =====
    // These provide access to the new static buffer architecture
    // UI components can migrate to these incrementally
    
    readonly property int storeVersion: WindowStore.version
    
    // Direct buffer access for high-performance scenarios
    readonly property var windowBuffer: WindowStore.windowBuffer
    readonly property var workspaceBuffer: WindowStore.workspaceBuffer
    
    // Accessor functions that use the new store
    function getWindowFromStore(windowId) {
        return WindowStore.getWindow(windowId);
    }
    
    function getWorkspaceFromStore(workspaceId) {
        return WindowStore.getWorkspace(workspaceId);
    }
    
    function getWindowsFromStoreForWorkspace(workspaceId) {
        return WindowStore.getWindowsForWorkspace(workspaceId);
    }
    
    function getFocusedWindowFromStore() {
        return WindowStore.getFocusedWindow();
    }
    
    function getFocusedWorkspaceFromStore() {
        return WindowStore.getFocusedWorkspace();
    }
    
    // Window grouping from new architecture
    function getGroupsForWorkspace(workspaceId, forceRebuild) {
        return WindowGrouper.getGroupsForWorkspace(workspaceId, forceRebuild || false);
    }
    
    function getWindowsInGroup(groupSlot) {
        return WindowGrouper.getWindowsInGroup(groupSlot);
    }
    
    // Debug helpers
    function dumpStoreState() {
        WindowStore.debugDump();
        WindowGrouper.debugDump();
    }
}
