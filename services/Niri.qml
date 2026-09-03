pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.utils

Singleton {
    id: root

    // Scroll direction tracking
    property int lastFocusedColumn: -1
    property string scrollDirection: "none" // "left", "right", "none"

    // Workspace management
    property var wsContextExpanded: false
    property var wsContextAnchor: null
    property string wsContextType: "none" // "item", "workspace", "workspaces", "none"
    property Timer wsAnchorClearTimer: Timer {
        interval: Appearance.anim.durations.normal // ms, adjust as you like
        repeat: false
        onTriggered: {
            if (root.wsContextAnchor === null) {
                root.wsContextType = "none";
            }
        }
    }

    onWsContextAnchorChanged: {
        // cancel any existing countdown
        wsAnchorClearTimer.stop();
        // only start timer if it’s null
        if (wsContextAnchor === null) {
            wsAnchorClearTimer.start();
        }
    }

    // Outputs / Monitor management:
    property var outputs: ({})

    // Overview state
    property bool inOverview: false

    // Keyboard layout

    // TODO: Add capslock and numlock in the future

    property var kbLayoutsArray: []
    property bool capsLock: false
    property bool numLock: false
    property string defaultKbLayout: kbLayouts[0] || "?"
    property int kbLayoutIndex: 0
    property string kbLayouts: "?"
    readonly property string kbLayout: (kbLayoutsArray.length > 0 && kbLayoutIndex >= 0 && kbLayoutIndex < kbLayoutsArray.length) ? kbLayoutsArray[kbLayoutIndex].slice(0, 2).toLowerCase() : "?"

    Connections {
        target: ActiveWindowModel

        function onFocusSerialChanged(): void {
            const pos = ActiveWindowModel.window?.layout?.pos_in_scrolling_layout;
            if (!Array.isArray(pos)) {
                root.scrollDirection = "none";
                return;
            }

            const currentCol = pos[0];
            if (root.lastFocusedColumn >= 0)
                root.scrollDirection = currentCol > root.lastFocusedColumn ? "right" : currentCol < root.lastFocusedColumn ? "left" : "none";
            root.lastFocusedColumn = currentCol;
        }
    }

    // Feature availability
    property bool niriAvailable: false

    Component.onCompleted: {
        checkNiriAvailability();

    }

    // Check if niri is available
    Process {
        id: niriCheck
        command: ["which", "niri"]
        onExited: exitCode => {
            root.niriAvailable = exitCode === 0;
            if (root.niriAvailable) {
                eventStreamProcess.running = true;
                root.loadInitialWorkspaceData();
            }
        }
    }

    function checkNiriAvailability() {
        niriCheck.running = true;
    }

    // Load initial workspace data
    Process {
        id: initialDataQuery
        command: ["niri", "msg", "-j", "workspaces"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const workspaces = JSON.parse(text.trim());
                        WMStateMachine.enqueue(WMStateMachine.evtWorkspacesChanged, {
                            workspaces: workspaces
                        });
                    } catch (e) {
                        console.warn("NiriService: Failed to parse initial workspace data:", e);
                    }
                }
            }
        }
    }

    // Load initial outputs data
    Process {
        id: initialOutputsQuery
        command: ["niri", "msg", "-j", "outputs"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const outputsData = JSON.parse(text.trim());
                        root.handleOutputsChanged(outputsData);
                    } catch (e) {
                        console.warn("NiriService: Failed to parse initial outputs data:", e);
                    }
                }
            }
        }
    }

    // Load initial windows data
    Process {
        id: initialWindowsQuery
        command: ["niri", "msg", "-j", "windows"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const windowsData = JSON.parse(text.trim());
                        const payload = Array.isArray(windowsData) ? {
                            windows: windowsData
                        } : windowsData;
                        if (payload && payload.windows) {
                            WMStateMachine.enqueue(WMStateMachine.evtWindowsChanged, payload);
                        }
                    } catch (e) {
                        console.warn("NiriService: Failed to parse initial windows data:", e);
                    }
                }
            }
        }
    }

    // Load initial focused window data
    Process {
        id: initialFocusedWindowQuery
        command: ["niri", "msg", "-j", "focused-window"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        const focusedData = JSON.parse(text.trim());
                        if (focusedData && focusedData.id) {
                            WMStateMachine.enqueue(WMStateMachine.evtWindowFocused, {
                                id: focusedData.id
                            });
                        }
                    } catch (e) {
                        console.warn("NiriService: Failed to parse initial focused window data:", e);
                    }
                }
            }
        }
    }

    function loadInitialWorkspaceData() {
        initialDataQuery.running = true;
        initialWindowsQuery.running = true;
        initialFocusedWindowQuery.running = true;
        initialOutputsQuery.running = true; // Add this line
    }

    // Event stream restart backoff
    property int eventStreamRestartAttempts: 0

    Timer {
        id: eventStreamRestartBackoff
        interval: Math.min(1000 * Math.pow(2, root.eventStreamRestartAttempts), 30000)
        repeat: false
        onTriggered: {
            eventStreamProcess.running = true;
        }
    }

    // Event stream for real-time updates
    Process {
        id: eventStreamProcess
        command: ["niri", "msg", "-j", "event-stream"]
        running: false // Will be enabled after niri check

        onRunningChanged: {
            if (running) {
                root.eventStreamRestartAttempts = 0;
            }
        }

        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data.trim());
                    root.handleNiriEvent(event);
                } catch (e) {
                    console.warn("NiriService: Failed to parse event:", data, e);
                }
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0 && root.niriAvailable) {
                root.eventStreamRestartAttempts++;
                console.warn("NiriService: Event stream exited with code", exitCode, 
                    "- restarting in", eventStreamRestartBackoff.interval, "ms (attempt", root.eventStreamRestartAttempts + ")");
                eventStreamRestartBackoff.start();
            }
        }
    }

    function handleNiriEvent(event) {
        if (event.WorkspacesChanged) {
            WMStateMachine.enqueue(WMStateMachine.evtWorkspacesChanged, event.WorkspacesChanged);
        } else if (event.WorkspaceActivated) {
            WMStateMachine.enqueue(WMStateMachine.evtWorkspaceActivated, event.WorkspaceActivated);
        } else if (event.WindowLayoutsChanged) {
            WMStateMachine.enqueue(WMStateMachine.evtLayoutChanged, event.WindowLayoutsChanged);
        } else if (event.WindowsChanged) {
            WMStateMachine.enqueue(WMStateMachine.evtWindowsChanged, event.WindowsChanged);
        } else if (event.WindowClosed) {
            WMStateMachine.enqueue(WMStateMachine.evtWindowClosed, event.WindowClosed);
        } else if (event.WindowFocusChanged) {
            WMStateMachine.enqueue(WMStateMachine.evtWindowFocused, event.WindowFocusChanged);
        } else if (event.WindowOpenedOrChanged) {
            WMStateMachine.enqueue(WMStateMachine.evtWindowOpened, event.WindowOpenedOrChanged);
        } else if (event.OverviewOpenedOrClosed) {
            handleOverviewChanged(event.OverviewOpenedOrClosed);
        } else if (event.KeyboardLayoutsChanged) {
            handleKeyboardLayoutsChanged(event.KeyboardLayoutsChanged);
        }
    }
    function handleKeyboardLayoutsChanged(data) {
        if (data && data.keyboard_layouts && data.keyboard_layouts.names && data.keyboard_layouts.names.length > 0) {
            kbLayoutsArray = data.keyboard_layouts.names;
            kbLayouts = data.keyboard_layouts.names.join(",");
            var idx = data.keyboard_layouts.current_idx;
            if (idx >= 0 && idx < data.keyboard_layouts.names.length) {
                kbLayoutIndex = idx;
            } else {
                kbLayoutIndex = 0;
            }
        } else {
            kbLayoutsArray = [];
            kbLayouts = "?";
            kbLayoutIndex = 0;
        }
    }

    function handleOutputsChanged(data) {
        outputs = data;
    }

    function handleOverviewChanged(data) {
        inOverview = data.is_open;
    }

    function cleanWindowTitle(windowTitle) {
        if (windowTitle) {
            return windowTitle.replace(/^[^\x20-\x7E]+/, "");
        }
        return windowTitle;
    }

    // Public API functions
    function getActiveWorkspaceName() {
        return WorkspaceModel.focusedWorkspace?.name || "";
    }

    function getWorkspaceNameByIndex(idx) {
        return WorkspaceModel.getWorkspaceNameByIndex(idx);
    }

    function getWorkspaceNameById(id) {
        return WorkspaceModel.getWorkspaceNameById(id);
    }

    function getActiveWorkspaceWindows() {
        return WindowCollectionModel.getWindowsByWorkspaceId(WorkspaceModel.focusedWorkspaceId);
    }

    function getWindowsByWorkspaceId(wsid) {
        return WindowCollectionModel.getWindowsByWorkspaceId(wsid);
    }

    function getWindowsByWorkspaceIndex(index) {
        return WindowCollectionModel.getWindowsByWorkspaceIndex(index);
    }

    function switchToWorkspace(workspaceId) {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", workspaceId.toString()]);
        return true;
    }

    function switchToWorkspaceUpDown(string) {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `focus-workspace-${string}`]);
        return true;
    }

    function toggleWindowFloating(windowId) {
        if (!niriAvailable)
            return false;
        const targetId = windowId || ActiveWindowModel.idString;
        if (!targetId)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `toggle-window-floating`, `--id`, targetId.toString()]);
        return true;
    }

    function focusWindow(windowID) {
        if (!niriAvailable)
            return false;

        if (Number(windowID) === Number(ActiveWindowModel.idString) && Config.bar.workspaces.doubleClickToCenter) {
            centerWindow();
            return true;
        }

        Quickshell.execDetached(["niri", "msg", "action", `focus-window`, `--id`, windowID.toString()]);
        return true;
    }

    function closeFocusedWindow() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `close-window`]);
        return true;
    }

    function closeWindow(windowId) {
        if (!niriAvailable)
            return false;
        const targetId = windowId || ActiveWindowModel.idString;
        if (!targetId)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `close-window`, `--id`, targetId.toString()]);
        return true;
    }

    function toggleWindowOpacity() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `toggle-window-rule-opacity`]);
        return true;
    }

    function expandColumnToAvailable() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `expand-column-to-available-width`]);
        return true;
    }

    function centerWindow() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `center-window`]);
        return true;
    }

    function screenshotWindow() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `screenshot-window`]);
        return true;
    }

    function keyboardShortcutsInhibitWindow() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `toggle-keyboard-shortcuts-inhibit`]);
        return true;
    }

    function toggleWindowedFullscreen() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `toggle-windowed-fullscreen`]);
        return true;
    }

    function toggleFullscreen() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `fullscreen-window`]);
        return true;
    }

    function toggleMaximize() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `maximize-column`]);
        return true;
    }

    function toggleOverview() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `toggle-overview`]);
        return true;
    }

    function dispatch(cmd) {
        // Fallback/Placeholder for generic dispatch commands
        // This handles commands like 'pin address:...' which might come from shared code
        console.warn("NiriService: dispatch called with command:", cmd);
        
        // Example: Try to map 'pin address:...' to niri? 
        // For now, just logging to prevent crash.
        return false;
    }

    function doScreenTransition(delayMs = 500) {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `do-screen-transition -d`, delayMs.toString()]);
        return true;
    }

    function moveGroupColumnsSequential(curWindowId, windowIds, targetIndex, delayMs) {
        var i = 0;
        // toggleOverview();
        function moveNext() {
            if (i >= windowIds.length) {
                // After all moves, focus curWindowId, hax!
                var timer = Qt.createQmlObject('import QtQuick 2.0; Timer { interval: ' + (delayMs * (i + 1) || 100) + '; repeat: false }', root);
                timer.triggered.connect(function () {
                    timer.stop();
                    timer.destroy();
                    // toggleOverview();

                    focusWindow(Number(curWindowId));
                    i++;
                });
                timer.start();
                return;
            }

            var windowId = windowIds[i];
            var timer = Qt.createQmlObject('import QtQuick 2.0; Timer { interval: ' + (delayMs * (i + 1) || 100) + '; repeat: false }', root);
            timer.triggered.connect(function () {
                timer.stop();
                timer.destroy();
                Niri.moveColumnToIndexAfterFocus(windowId, targetIndex);
                i++;
                moveNext();
            });
            timer.start();
        }
        moveNext();
    }

    function moveColumnToIndexAfterFocus(windowId, index, delayMs = 2) {
        if (!niriAvailable)
            return false;

        if (Number(windowId) === Number(ActiveWindowModel.idString)) {
            // Already focused,
            Quickshell.execDetached(["niri", "msg", "action", "move-column-to-index", index.toString()]);
            return true;
        }

        focusWindow(windowId);

        var delay = delayMs !== undefined ? delayMs : 25; // Default to 25ms
        var timer = Qt.createQmlObject('import QtQuick 2.0; Timer { interval: ' + delay + '; repeat: false }', root);
        timer.triggered.connect(function () {
            timer.stop();
            timer.destroy();
            Quickshell.execDetached(["niri", "msg", "action", "move-column-to-index", index.toString()]);
        });
        timer.start();
        return true;
    }

    function moveColumnToIndex(windowId, index) {
        if (!niriAvailable)
            return false;
        if (focusWindow(windowId)) {
            Quickshell.execDetached(["niri", "msg", "action", `move-column-to-index`, index.toString()]);
            return true;
        }
        return true;
    }

    function moveWindowToWorkspace(workspaceId) {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `move-window-to-workspace`, workspaceId.toString()]);
        return true;
    }

    function switchToWorkspaceByIndex(index) {
        if (!niriAvailable)
            return false;
        var workspace = WorkspaceModel.getWorkspaceByIndex(index);
        if (!workspace)
            return false;
        return switchToWorkspace(workspace.id);
    }

    function switchToWorkspaceByNumber(number, output) {
        if (!niriAvailable)
            return false;
        var targetOutput = output || WorkspaceModel.focusedMonitorName;
        if (!targetOutput) {
            console.warn("NiriService: No output specified for workspace switching");
            return false;
        }
        var outputWorkspaces = WorkspaceModel.getWorkspacesForOutput(targetOutput).slice().sort((a, b) => a.idx - b.idx);
        if (number >= 1 && number <= outputWorkspaces.length) {
            var workspace = outputWorkspaces[number - 1];
            return switchToWorkspace(workspace.id);
        }
        console.warn("NiriService: No workspace", number, "found on output", targetOutput);
        return false;
    }

    function getWorkspaceByIndex(index) {
        return WorkspaceModel.getWorkspaceByIndex(index);
    }

    function getWorkspaceCount() {
        return WorkspaceModel.workspaceCount;
    }

    function getOccupiedWorkspaceCount() {
        let count = 0;
        const occupied = WorkspaceModel.workspaceHasWindows || {};
        for (const key in occupied) {
            if (occupied[key])
                count++;
        }
        return count;
    }

    // Picker helpers
    function getCurrentOutputWorkspaceNumbers() {
        return WorkspaceModel.currentOutputWorkspaces.map(w => w.idx + 1);
    }

    function getCurrentWorkspaceNumber() {
        return (WorkspaceModel.focusedWorkspace?.idx ?? 0) + 1;
    }

    function getWindowsInScreen(screenX, screenY, screenWidth, screenHeight, windowBorder, padding) {
        const focusedWindow = ActiveWindowModel.window;
        if (!focusedWindow?.layout?.pos_in_scrolling_layout)
            return [];
        const focusedCol = focusedWindow.layout.pos_in_scrolling_layout[0];
        const focusedRow = focusedWindow.layout.pos_in_scrolling_layout[1];
        return getActiveWorkspaceWindows().map(window => {
            if (!window.layout?.pos_in_scrolling_layout || !window.layout?.window_size)
                return null;
            const colOffset = window.layout.pos_in_scrolling_layout[0] - focusedCol;
            const rowOffset = window.layout.pos_in_scrolling_layout[1] - focusedRow;
            const focusedWidth = focusedWindow.layout.window_size[0];
            let focusedScreenX;
            if (focusedWidth < screenWidth - windowBorder) {
                focusedScreenX = scrollDirection === "left" ? 5 : screenWidth - focusedWidth;
            } else {
                focusedScreenX = 0;
            }
            const winX = focusedScreenX + (colOffset * window.layout.window_size[0]) - windowBorder;
            const winY = rowOffset * window.layout.window_size[1] + windowBorder;
            const winW = window.layout.window_size[0] - padding * 2;
            const winH = window.layout.window_size[1] - padding * 2;
            if (winX < screenWidth + windowBorder && winY < screenHeight && winX + winW > 0 && winY + winH > 0) {
                return {
                    window: window,
                    screenX: winX,
                    screenY: winY,
                    screenW: winW,
                    screenH: winH
                };
            }
            return null;
        }).filter(item => item !== null);
    }
}
