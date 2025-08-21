pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Scroll direction tracking
    property int lastFocusedColumn: -1
    property string scrollDirection: "none" // "left", "right", "none"

    // Workspace management
    property var wsAnchorItem: null
    property var wsItemWindows: null

    // Workspace management
    property var allWorkspaces: []
    property int focusedWorkspaceIndex: 0
    property string focusedWorkspaceId: ""
    property var currentOutputWorkspaces: []

    // Window management
    property var windows: []
    property int focusedWindowIndex: -1
    property string focusedWindowTitle: "(No active window)"
    property string focusedWindowClass: "(No active window)"
    property string focusedWindowId: ""

    // Outputs / Monitor management:
    property var outputs: ({})
    property string focusedMonitorName: ""

    onOutputsChanged: console.log(outputs)

    // Overview state
    property bool inOverview: false

    signal windowOpenedOrChanged(var windowData)

    // Last focused window
    property var focusedWindow: root.windows[root.focusedWindowIndex]
    property var lastFocusedWindow: null
    // Monitor changes to focusedWindowId to update lastFocusedWindow
    onFocusedWindowIdChanged: {
        if (focusedWindow) {
            // Only update if a window is truly focused
            root.lastFocusedWindow = focusedWindow;
            // Track scroll direction
            if (focusedWindow.layout?.pos_in_scrolling_layout) {
                const currentCol = focusedWindow.layout.pos_in_scrolling_layout[0];
                if (lastFocusedColumn >= 0) {
                    scrollDirection = currentCol > lastFocusedColumn ? "right" : currentCol < lastFocusedColumn ? "left" : "none";
                }
                lastFocusedColumn = currentCol;
            }
        }

        // console.log(JSON.stringify(focusedWindow));
        // console.log(JSON.stringify(focusedWindow.layout.pos_in_scrolling_layout));
    }

    property var workspaceHasWindows: ({})
    function updateWorkspaceHasWindows() {
        let newWorkspaceHasWindows = {};

        // Initialize all known workspaces to false
        for (const ws of root.allWorkspaces) {
            // Use allWorkspaces here
            newWorkspaceHasWindows[ws.idx] = false;
        }

        // Iterate through all windows and mark their workspace as having windows
        for (const window of root.windows) {
            if (window.workspace_id !== undefined && window.workspace_id !== null) {
                newWorkspaceHasWindows[getWorkspaceIdxById(window.workspace_id)] = true;
            }
        }
        // Only update if there's an actual change to avoid unnecessary property change signals
        if (JSON.stringify(root.workspaceHasWindows) !== JSON.stringify(newWorkspaceHasWindows)) {
            root.workspaceHasWindows = newWorkspaceHasWindows;
            console.log("NiriService: updateWorkspaceHasWindows() called. Current state:", JSON.stringify(root.workspaceHasWindows));
        }
    }

    function getWorkspaceIdxById(workspaceId) {
        const ws = allWorkspaces.find(w => w.id === workspaceId);
        return ws ? ws.idx : -1;
    }

    // Call updateWorkspaceHasWindows when relevant properties change
    onAllWorkspacesChanged: updateWorkspaceHasWindows() // Update if workspaces themselves change
    onWindowsChanged: updateWorkspaceHasWindows() // Explicitly update when the windows list changes

    // Feature availability
    property bool niriAvailable: false

    Component.onCompleted: {
        console.log("NiriService: Component.onCompleted - initializing service");
        checkNiriAvailability();
    }

    // Check if niri is available
    Process {
        id: niriCheck
        command: ["which", "niri"]

        onExited: exitCode => {
            root.niriAvailable = exitCode === 0;
            if (root.niriAvailable) {
                console.log("NiriService: niri found, starting event stream and loading initial data");
                eventStreamProcess.running = true;
                root.loadInitialWorkspaceData();
            } else {
                console.log("NiriService: niri not found, workspace features disabled");
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
                        console.log("NiriService: Loaded initial workspace data");
                        const workspaces = JSON.parse(text.trim());
                        // Initial query returns array directly, event stream wraps it in WorkspacesChanged
                        root.handleWorkspacesChanged({
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
                        if (windowsData && windowsData.windows) {
                            root.handleWindowsChanged(windowsData);
                            console.log("NiriService: Loaded", windowsData.windows.length, "initial windows");
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
                            root.handleWindowFocusChanged({
                                id: focusedData.id
                            });
                            console.log("NiriService: Loaded initial focused window:", focusedData.id);
                        }
                    } catch (e) {
                        console.warn("NiriService: Failed to parse initial focused window data:", e);
                    }
                }
            }
        }
    }

    function loadInitialWorkspaceData() {
        console.log("NiriService: Loading initial workspace data...");
        initialDataQuery.running = true;
        initialWindowsQuery.running = true;
        initialFocusedWindowQuery.running = true;
        initialOutputsQuery.running = true; // Add this line
    }

    // Event stream for real-time updates
    Process {
        id: eventStreamProcess
        command: ["niri", "msg", "-j", "event-stream"]
        running: false // Will be enabled after niri check

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
                console.warn("NiriService: Event stream exited with code", exitCode, "restarting immediately");
                eventStreamProcess.running = true;
            }
        }
    }

    function handleNiriEvent(event) {
        if (event.WorkspacesChanged) {
            handleWorkspacesChanged(event.WorkspacesChanged);
        } else if (event.WorkspaceActivated) {
            handleWorkspaceActivated(event.WorkspaceActivated);
        } else if (event.WindowsChanged) {
            handleWindowsChanged(event.WindowsChanged);
        } else if (event.WindowClosed) {
            handleWindowClosed(event.WindowClosed);
        } else if (event.WindowFocusChanged) {
            handleWindowFocusChanged(event.WindowFocusChanged);
        } else if (event.WindowOpenedOrChanged) {
            handleWindowOpenedOrChanged(event.WindowOpenedOrChanged);
        } else if (event.OverviewOpenedOrClosed) {
            handleOverviewChanged(event.OverviewOpenedOrClosed);
        } else if (event.WindowLayoutsChanged) {
            handleWindowLayoutsChanged(event.WindowLayoutsChanged);
        }
    }

    function handleWindowLayoutsChanged(data) {
        if (!data.changes)
            return;

        var updatedWindows = windows.slice(); // copy array
        for (var i = 0; i < data.changes.length; i++) {
            var id = data.changes[i][0];
            var layout = data.changes[i][1];
            var idx = -1;

            for (var j = 0; j < updatedWindows.length; j++) {
                if (updatedWindows[j].id === id) {
                    idx = j;
                    break;
                }
            }

            if (idx >= 0) {
                updatedWindows[idx] = Object.assign({}, updatedWindows[idx], {
                    layout: layout
                });
            }
        }
        windows = updatedWindows;
    }

    function handleWorkspacesChanged(data) {
        // console.log(allWorkspaces.length, "workspaces found");
        // console.log(windows.length, "windows found");

        allWorkspaces = [...data.workspaces].sort((a, b) => a.idx - b.idx);

        // console.log(allWorkspaces.length, "workspaces sorted");
        // console.log(JSON.stringify(allWorkspaces, null, 2));

        // Update focused workspace
        focusedWorkspaceIndex = allWorkspaces.findIndex(w => w.is_focused);
        if (focusedWorkspaceIndex >= 0) {
            var focusedWs = allWorkspaces[focusedWorkspaceIndex];
            focusedWorkspaceId = focusedWs.id;
            focusedMonitorName = focusedWs.output;
            console.log(focusedMonitorName);
        } else {
            focusedWorkspaceIndex = 0;
            focusedWorkspaceId = "";
        }

        updateCurrentOutputWorkspaces();
    }

    function handleWorkspaceActivated(data) {
        // Update focused workspace
        focusedWorkspaceId = data.id;
        focusedWorkspaceIndex = allWorkspaces.findIndex(w => w.id === data.id);

        if (focusedWorkspaceIndex >= 0) {
            var activatedWs = allWorkspaces[focusedWorkspaceIndex];

            // Update workspace states properly
            // First, deactivate all workspaces on this output
            for (var i = 0; i < allWorkspaces.length; i++) {
                if (allWorkspaces[i].output === activatedWs.output) {
                    allWorkspaces[i].is_active = false;
                    allWorkspaces[i].is_focused = false;
                }
            }

            // Then activate the new workspace
            allWorkspaces[focusedWorkspaceIndex].is_active = true;
            allWorkspaces[focusedWorkspaceIndex].is_focused = data.focused || false;

            focusedMonitorName = activatedWs.output || "";

            updateCurrentOutputWorkspaces();

            // Force property change notifications
            allWorkspacesChanged();
        } else {
            focusedWorkspaceIndex = 0;
        }
    }

    function handleWindowsChanged(data) {
        var newWindows = data.windows.slice(); // shallow copy

        // Ensure layout objects exist
        for (var i = 0; i < newWindows.length; i++) {
            if (!newWindows[i].layout) {
                newWindows[i].layout = {};
            }
        }

        // Sort by id for consistency
        newWindows.sort(function (a, b) {
            return a.id - b.id;
        });

        windows = newWindows;
        updateFocusedWindow();
    }

    function handleWindowClosed(data) {
        windows = windows.filter(w => w.id !== data.id);
        updateFocusedWindow();
    }

    function handleWindowFocusChanged(data) {
        if (data.id) {
            focusedWindowId = data.id;
            focusedWindowIndex = windows.findIndex(w => w.id === data.id);
        } else {
            focusedWindowId = "";
            focusedWindowIndex = -1;
        }
        updateFocusedWindow();
    }

    function handleOutputsChanged(data) {
        outputs = data;
        console.log("NiriService: Updated outputs:", Object.keys(outputs));
    }

    function handleWindowOpenedOrChanged(data) {
        if (!data.window)
            return;

        var window = data.window;
        var updatedWindows = windows.slice();
        var existingIndex = updatedWindows.findIndex(function (w) {
            return w.id === window.id;
        });

        if (existingIndex >= 0) {
            // Merge properties safely
            updatedWindows[existingIndex] = Object.assign({}, updatedWindows[existingIndex], window);
        } else {
            updatedWindows.push(window);
        }

        // Sort for stability
        updatedWindows.sort(function (a, b) {
            return a.id - b.id;
        });
        windows = updatedWindows;

        // If focused, update state
        if (window.is_focused) {
            focusedWindowId = window.id;
            focusedWindowIndex = updatedWindows.findIndex(function (w) {
                return w.id === window.id;
            });
        }

        updateFocusedWindow();

        // Emit signal for others
        windowOpenedOrChanged(window);
    }

    function handleOverviewChanged(data) {
        inOverview = data.is_open;
    }

    function updateCurrentOutputWorkspaces() {
        if (!focusedMonitorName) {
            currentOutputWorkspaces = allWorkspaces;
            return;
        }

        // Filter workspaces for current output
        var outputWs = allWorkspaces.filter(w => w.output === focusedMonitorName);
        currentOutputWorkspaces = outputWs;
    }

    function updateFocusedWindow() {
        if (focusedWindowIndex >= 0 && focusedWindowIndex < windows.length) {
            var focusedWin = windows[focusedWindowIndex];
            focusedWindowTitle = focusedWin.title || "(Unnamed window)";
            focusedWindowClass = focusedWin.app_id || "";
        } else {
            focusedWindowTitle = "";
            focusedWindowClass = "Desktop";
        }
    }

    // Public API functions
    function getActiveWorkspaceName() {
        if (root.allWorkspaces && root.focusedWorkspaceIndex >= 0 && root.focusedWorkspaceIndex < root.allWorkspaces.length) {
            return root.allWorkspaces[root.focusedWorkspaceIndex].name || "";
        }
        return "";
    }

    function getWorkspaceNameByIndex(idx) {
        if (root.allWorkspaces && idx >= 0 && idx < root.allWorkspaces.length) {
            return root.allWorkspaces[idx].name || "";
        }
        return "";
    }

    function getActiveWorkspaceWindows() {
        // Defensive: check bounds
        if (!root.allWorkspaces || root.focusedWorkspaceIndex === undefined)
            return [];

        var currentWorkspaceObj = root.allWorkspaces[root.focusedWorkspaceIndex];
        if (!currentWorkspaceObj || currentWorkspaceObj.id === undefined)
            return [];

        var currentWorkspaceId = currentWorkspaceObj.id;
        return root.windows ? root.windows.filter(function (windowObj) {
            return windowObj.workspace_id === currentWorkspaceId;
        }) : [];
    }

    function getWindowsByWorkspaceId(wsid) {
        const windowsByWorkspace = {};
        for (const workspace of allWorkspaces) {
            windowsByWorkspace[workspace.id] = windows.filter(window => window.workspace_id === workspace.id);
        }
        return windowsByWorkspace[wsid] || [];
    }

    function getWindowsByWorkspaceIndex(index) {
        if (index < 0 || index >= allWorkspaces.length)
            return [];

        const workspaceId = allWorkspaces[index].id;
        return windows.filter(window => window.workspace_id === workspaceId);
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

    function toggleWindowFloating() {
        if (!niriAvailable)
            return false;

        Quickshell.execDetached(["niri", "msg", "action", `toggle-window-floating`]);
        return true;
    }

    function focusWindow(windowID) {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `focus-window`, `--id`, windowID.toString()]);
        return true;
    }

    function closeFocusedWindow() {
        if (!niriAvailable)
            return false;
        Quickshell.execDetached(["niri", "msg", "action", `close-window`]);
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

    function moveWindowToWorkspace(workspaceId) {
        if (!niriAvailable)
            return false;

        Quickshell.execDetached(["niri", "msg", "action", `move-window-to-workspace`, workspaceId.toString()]);
        return true;
    }

    function switchToWorkspaceByIndex(index) {
        if (!niriAvailable || index < 0 || index >= allWorkspaces.length)
            return false;

        var workspace = allWorkspaces[index];
        return switchToWorkspace(workspace.id);
    }

    function switchToWorkspaceByNumber(number, output) {
        if (!niriAvailable)
            return false;

        var targetOutput = output || focusedMonitorName;
        if (!targetOutput) {
            console.warn("NiriService: No output specified for workspace switching");
            return false;
        }

        // Get workspaces for the target output, sorted by idx
        var outputWorkspaces = allWorkspaces.filter(w => w.output === targetOutput).sort((a, b) => a.idx - b.idx);

        // Use sequential index (number is 1-based, array is 0-based)
        if (number >= 1 && number <= outputWorkspaces.length) {
            var workspace = outputWorkspaces[number - 1];
            return switchToWorkspace(workspace.id);
        }

        console.warn("NiriService: No workspace", number, "found on output", targetOutput);
        return false;
    }

    function getWorkspaceByIndex(index) {
        if (index >= 0 && index < allWorkspaces.length) {
            return allWorkspaces[index];
        }
        return null;
    }

    function getWorkspaceCount() {
        return allWorkspaces.length;
    }

    function getCurrentOutputWorkspaceNumbers() {
        return currentOutputWorkspaces.map(w => w.idx + 1); // niri uses 0-based, UI shows 1-based
    }

    function getCurrentWorkspaceNumber() {
        if (focusedWorkspaceIndex >= 0 && focusedWorkspaceIndex < allWorkspaces.length) {
            return allWorkspaces[focusedWorkspaceIndex].idx + 1;
        }
        return 1;
    }

    function getWindowsInScreen(screenX, screenY, screenWidth, screenHeight, windowBorder, padding) {
        if (!focusedWindow?.layout?.pos_in_scrolling_layout)
            return [];

        const focusedCol = focusedWindow.layout.pos_in_scrolling_layout[0];
        const focusedRow = focusedWindow.layout.pos_in_scrolling_layout[1];

        return getActiveWorkspaceWindows().map(window => {
            if (!window.layout?.pos_in_scrolling_layout || !window.layout?.window_size)
                return null;

            // Calculate screen position relative to focused window
            const colOffset = window.layout.pos_in_scrolling_layout[0] - focusedCol;
            const rowOffset = window.layout.pos_in_scrolling_layout[1] - focusedRow;

            // In getWindowsInScreen()
            const focusedWidth = focusedWindow.layout.window_size[0];
            let focusedScreenX;

            if (focusedWidth < screenWidth - windowBorder) {
                // Use scroll direction to determine alignment
                focusedScreenX = scrollDirection === "left" ? 5 : screenWidth - focusedWidth;
            } else {
                focusedScreenX = 0;
            }

            const winX = focusedScreenX + (colOffset * window.layout.window_size[0]) - windowBorder;

            // const winX = colOffset * window.layout.window_size[0];
            const winY = rowOffset * window.layout.window_size[1] + windowBorder;
            const winW = window.layout.window_size[0] - padding * 2;
            const winH = window.layout.window_size[1] - padding * 2;

            // Check if window intersects with screen bounds
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
