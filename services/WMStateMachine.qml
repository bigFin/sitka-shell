pragma Singleton
pragma ComponentBehavior: Bound

/*
 * WMStateMachine - Event Batching State Machine
 *
 * This singleton batches rapid window manager events and processes them
 * efficiently in 16ms windows (~60fps), preventing UI thrashing.
 *
 * States: Idle -> Collecting -> Processing -> Committing -> Idle
 *
 * Events are coalesced: multiple events of the same type within the
 * batch window are merged, window upserts are keyed by window id, and
 * window closes are kept in order.
 *
 * Niri.qml feeds compositor events here; UI consumers read WindowStore-driven
 * derived models instead of raw compositor arrays.
 */

import QtQuick
import Quickshell
import "."

Singleton {
    id: machine

    // ===== STATE MACHINE STATES =====
    readonly property int stateIdle: 0
    readonly property int stateCollecting: 1
    readonly property int stateProcessing: 2
    readonly property int stateCommitting: 3

    property int currentState: stateIdle

    // ===== EVENT QUEUE =====
    property var eventQueue: []
    readonly property int maxQueueSize: 100
    readonly property bool batchTimerRunning: batchTimer.running
    property int queuedEventCount: 0
    property int processedBatchCount: 0
    property int processedEventCount: 0
    property int lastBatchSize: 0
    property int lastCoalescedSize: 0
    property double lastQueuedAt: 0
    property double lastProcessedAt: 0
    property var queuedByType: ({})
    property var processedByType: ({})
    property int skippedEventCount: 0
    property int quietTitleUpdateCount: 0
    property var skippedByType: ({})
    property bool lastEventCollectionChanged: false

    // ===== BATCH TIMER =====
    Timer {
        id: batchTimer
        interval: 16  // ~60fps coalescing window
        repeat: false
        onTriggered: machine.processEvents()
    }

    // ===== EVENT TYPES =====
    readonly property string evtWorkspacesChanged: "workspaces_changed"
    readonly property string evtWorkspaceActivated: "workspace_activated"
    readonly property string evtWindowsChanged: "windows_changed"
    readonly property string evtWindowOpened: "window_opened"
    readonly property string evtWindowClosed: "window_closed"
    readonly property string evtWindowFocused: "window_focused"
    readonly property string evtLayoutChanged: "layout_changed"

    // ===== PUBLIC API =====

    function enqueue(eventType, payload) {
        if (eventType === evtWindowOpened && absorbQuietTitleUpdate(payload)) {
            skippedEventCount++;
            quietTitleUpdateCount++;
            skippedByType = incrementTypeCount(skippedByType, eventType);
            return;
        }

        if (eventQueue.length >= maxQueueSize) {
            console.warn("WMStateMachine: Event queue overflow, dropping oldest");
            eventQueue.shift();
        }

        eventQueue.push({
            type: eventType,
            data: payload,
            timestamp: Date.now()
        });
        queuedEventCount++;
        lastQueuedAt = Date.now();
        queuedByType = incrementTypeCount(queuedByType, eventType);

        if (currentState === stateIdle) {
            currentState = stateCollecting;
            batchTimer.start();
        } else if (currentState === stateCollecting && !batchTimer.running) {
            batchTimer.start();
        }
    }

    // ===== INTERNAL PROCESSING =====

    function processEvents() {
        if (eventQueue.length === 0) {
            currentState = stateIdle;
            return;
        }

        currentState = stateProcessing;

        // Coalesce events - copy and clear queue first to avoid losing events
        // that arrive during processing
        const eventsToProcess = eventQueue;
        eventQueue = [];
        const coalescedEvents = coalesceEvents(eventsToProcess);
        lastBatchSize = eventsToProcess.length;
        lastCoalescedSize = coalescedEvents.length;
        processedBatchCount++;
        processedEventCount += coalescedEvents.length;
        lastProcessedAt = Date.now();

        // Process each event
        let stateChanged = false;
        let collectionChanged = false;
        for (let i = 0; i < coalescedEvents.length; i++) {
            lastEventCollectionChanged = false;
            processedByType = incrementTypeCount(processedByType, coalescedEvents[i].type);
            const changed = applyEvent(coalescedEvents[i]);
            stateChanged = changed || stateChanged;
            collectionChanged = (changed && lastEventCollectionChanged) || collectionChanged;
        }

        // Commit changes
        currentState = stateCommitting;

        if (collectionChanged) {
            WindowStore._rebuildWorkspaceWindowSlots();
            WindowStore._incrementCollectionVersion();
        }

        if (stateChanged) {
            WindowStore._updateCounts();
            WindowStore._incrementVersion();
        }

        // If more events arrived during processing, restart the timer
        if (eventQueue.length > 0) {
            currentState = stateCollecting;
            batchTimer.start();
        } else {
            currentState = stateIdle;
        }
    }

    function incrementTypeCount(source, eventType) {
        const counts = Object.assign({}, source);
        counts[eventType] = (counts[eventType] || 0) + 1;
        return counts;
    }

    function queuedByTypeNow() {
        const counts = {};
        for (let i = 0; i < eventQueue.length; i++) {
            const type = eventQueue[i].type;
            counts[type] = (counts[type] || 0) + 1;
        }
        return counts;
    }

    function oldestEventAgeMs() {
        if (eventQueue.length === 0)
            return 0;
        return Date.now() - eventQueue[0].timestamp;
    }

    function absorbQuietTitleUpdate(data) {
        if (!data || !data.window)
            return false;

        const win = data.window;
        const slot = WindowStore.windowIdToSlot[win.id];
        if (slot === undefined)
            return false;

        const bufWin = WindowStore.windowBuffer[slot];
        if (!bufWin.valid || bufWin.isFocused || (win.is_focused || false))
            return false;

        const layout = win.layout || {};
        const pos = layout.pos_in_scrolling_layout || [0, 0];
        const tilePos = layout.tile_pos_in_workspace_view || [-1, -1];
        const size = layout.window_size || [0, 0];
        const title = win.title || "";

        const structuralChanged = bufWin.id !== win.id || bufWin.workspaceId !== win.workspace_id || bufWin.pid !== (win.pid || -1) || bufWin.appId !== (win.app_id || "") || bufWin.isFloating !== (win.is_floating || false) || bufWin.isUrgent !== (win.is_urgent || false) || bufWin.layoutCol !== pos[0] || bufWin.layoutRow !== pos[1] || bufWin.tilePosX !== tilePos[0] || bufWin.tilePosY !== tilePos[1] || bufWin.width !== size[0] || bufWin.height !== size[1];
        if (structuralChanged || bufWin.title === title)
            return false;

        bufWin.title = title;
        return true;
    }

    function coalesceEvents(events) {
        // Group by event type, keeping closes ordered while coalescing upserts
        // by window id. Niri reports both opened and changed windows through
        // WindowOpenedOrChanged, so preserving every upsert creates churn.
        const byType = {};
        const windowUpserts = {};
        const ordered = [];

        for (let i = 0; i < events.length; i++) {
            const event = events[i];
            const type = event.type;

            // Window closes must be kept in order.
            if (type === evtWindowClosed) {
                ordered.push(event);
            } else if (type === evtWindowOpened) {
                const windowId = event.data && event.data.window ? event.data.window.id : undefined;
                if (windowId === undefined || windowId === null) {
                    ordered.push(event);
                } else {
                    windowUpserts[windowId] = event;
                }
            } else {
                // Keep only the latest of each type
                byType[type] = event;
            }
        }

        // Add coalesced events
        for (const windowId in windowUpserts) {
            ordered.push(windowUpserts[windowId]);
        }
        for (const type in byType) {
            ordered.push(byType[type]);
        }

        return ordered;
    }

    function applyEvent(event) {
        switch (event.type) {
        case evtWorkspacesChanged:
            return updateWorkspaces(event.data);
        case evtWorkspaceActivated:
            return updateWorkspaceActivation(event.data);
        case evtWindowsChanged:
            return updateWindows(event.data);
        case evtWindowOpened:
            return addOrUpdateWindow(event.data);
        case evtWindowClosed:
            return removeWindow(event.data);
        case evtWindowFocused:
            return updateWindowFocus(event.data);
        case evtLayoutChanged:
            return updateWindowLayouts(event.data);
        default:
            console.warn("WMStateMachine: Unknown event type:", event.type);
            return false;
        }
    }

    // ===== UPDATE FUNCTIONS =====

    function updateWorkspaces(data) {
        if (!data || !data.workspaces)
            return false;

        let changed = false;
        const workspaces = data.workspaces;

        for (let i = 0; i < workspaces.length && i < WindowStore.maxWorkspaces; i++) {
            const ws = workspaces[i];
            const slot = WindowStore.workspaceBuffer[i];

            // Check if anything changed
            if (!slot.valid || slot.id !== ws.id || slot.idx !== ws.idx || slot.name !== (ws.name || "") || slot.output !== (ws.output || "") || slot.isActive !== (ws.is_active || false) || slot.isFocused !== (ws.is_focused || false)) {
                slot.valid = true;
                slot.id = ws.id;
                slot.idx = ws.idx;
                slot.name = ws.name || "";
                slot.output = ws.output || "";
                slot.isActive = ws.is_active || false;
                slot.isFocused = ws.is_focused || false;

                WindowStore.workspaceIdToSlot[ws.id] = i;

                if (ws.is_focused) {
                    WindowStore.focusedWorkspaceSlot = i;
                }

                changed = true;
            }
        }

        // Invalidate unused slots
        for (let i = workspaces.length; i < WindowStore.maxWorkspaces; i++) {
            if (WindowStore.workspaceBuffer[i].valid) {
                const oldId = WindowStore.workspaceBuffer[i].id;
                WindowStore.workspaceBuffer[i].valid = false;
                delete WindowStore.workspaceIdToSlot[oldId];
                if (WindowStore.focusedWorkspaceSlot === i) {
                    WindowStore.focusedWorkspaceSlot = -1;
                }
                changed = true;
            }
        }

        return changed;
    }

    function updateWorkspaceActivation(data) {
        if (!data || !data.id)
            return false;

        const slot = WindowStore.workspaceIdToSlot[data.id];
        if (slot === undefined)
            return false;

        // Clear previous focus
        for (let i = 0; i < WindowStore.maxWorkspaces; i++) {
            const ws = WindowStore.workspaceBuffer[i];
            if (ws.valid && ws.output === WindowStore.workspaceBuffer[slot].output) {
                ws.isActive = false;
                ws.isFocused = false;
            }
        }

        // Set new focus
        WindowStore.workspaceBuffer[slot].isActive = true;
        WindowStore.workspaceBuffer[slot].isFocused = data.focused || false;
        WindowStore.focusedWorkspaceSlot = slot;

        return true;
    }

    function updateWindows(data) {
        if (!data || !data.windows)
            return false;

        let changed = false;
        const seenIds = {};
        const windows = data.windows;

        // First pass: update or add windows
        for (let i = 0; i < windows.length; i++) {
            const win = windows[i];
            seenIds[win.id] = true;

            let slot = WindowStore.windowIdToSlot[win.id];
            if (slot === undefined) {
                slot = WindowStore._allocateWindowSlot();
                if (slot < 0)
                    continue;
                WindowStore.windowIdToSlot[win.id] = slot;
            }

            const bufWin = WindowStore.windowBuffer[slot];
            const layout = win.layout || {};
            const pos = layout.pos_in_scrolling_layout || [0, 0];
            const tilePos = layout.tile_pos_in_workspace_view || [-1, -1];
            const size = layout.window_size || [0, 0];

            if (!bufWin.valid || bufWin.id !== win.id || bufWin.workspaceId !== win.workspace_id || bufWin.pid !== (win.pid || -1) || bufWin.appId !== (win.app_id || "") || bufWin.title !== (win.title || "") || bufWin.isFocused !== (win.is_focused || false) || bufWin.isFloating !== (win.is_floating || false) || bufWin.isUrgent !== (win.is_urgent || false) || bufWin.layoutCol !== pos[0] || bufWin.layoutRow !== pos[1] || bufWin.tilePosX !== tilePos[0] || bufWin.tilePosY !== tilePos[1] || bufWin.width !== size[0] || bufWin.height !== size[1]) {
                bufWin.valid = true;
                bufWin.id = win.id;
                bufWin.workspaceId = win.workspace_id;
                bufWin.pid = win.pid || -1;
                bufWin.appId = win.app_id || "";
                bufWin.title = win.title || "";
                bufWin.isFocused = win.is_focused || false;
                bufWin.isFloating = win.is_floating || false;
                bufWin.isUrgent = win.is_urgent || false;
                bufWin.layoutCol = pos[0];
                bufWin.layoutRow = pos[1];
                bufWin.tilePosX = tilePos[0];
                bufWin.tilePosY = tilePos[1];
                bufWin.width = size[0];
                bufWin.height = size[1];

                if (win.is_focused) {
                    WindowStore.focusedWindowSlot = slot;
                }

                lastEventCollectionChanged = true;
                changed = true;
            }
        }

        // Second pass: invalidate removed windows
        for (let i = 0; i < WindowStore.maxWindows; i++) {
            const bufWin = WindowStore.windowBuffer[i];
            if (bufWin.valid && !seenIds[bufWin.id]) {
                delete WindowStore.windowIdToSlot[bufWin.id];
                bufWin.valid = false;
                if (WindowStore.focusedWindowSlot === i) {
                    WindowStore.focusedWindowSlot = -1;
                }
                lastEventCollectionChanged = true;
                changed = true;
            }
        }

        return changed;
    }

    function addOrUpdateWindow(data) {
        if (!data || !data.window)
            return false;

        const win = data.window;
        let slot = WindowStore.windowIdToSlot[win.id];

        if (slot === undefined) {
            slot = WindowStore._allocateWindowSlot();
            if (slot < 0)
                return false;
            WindowStore.windowIdToSlot[win.id] = slot;
        }

        const bufWin = WindowStore.windowBuffer[slot];
        const layout = win.layout || {};
        const pos = layout.pos_in_scrolling_layout || [0, 0];
        const tilePos = layout.tile_pos_in_workspace_view || [-1, -1];
        const size = layout.window_size || [0, 0];
        const isFocused = win.is_focused || false;
        const isFloating = win.is_floating || false;
        const isUrgent = win.is_urgent || false;
        const pid = win.pid || -1;
        const appId = win.app_id || "";
        const title = win.title || "";

        const titleChanged = bufWin.title !== title;
        const collectionChanged = !bufWin.valid || bufWin.id !== win.id || bufWin.workspaceId !== win.workspace_id || bufWin.pid !== pid || bufWin.appId !== appId || bufWin.isFloating !== isFloating || bufWin.isUrgent !== isUrgent || bufWin.layoutCol !== pos[0] || bufWin.layoutRow !== pos[1] || bufWin.tilePosX !== tilePos[0] || bufWin.tilePosY !== tilePos[1] || bufWin.width !== size[0] || bufWin.height !== size[1];
        const focusChanged = bufWin.isFocused !== isFocused;
        const focusSlotChanged = isFocused && WindowStore.focusedWindowSlot !== slot;
        const changed = collectionChanged || focusChanged || focusSlotChanged || (isFocused && titleChanged);

        if (!changed) {
            if (titleChanged)
                bufWin.title = title;
            return false;
        }

        bufWin.valid = true;
        bufWin.id = win.id;
        bufWin.workspaceId = win.workspace_id;
        bufWin.pid = pid;
        bufWin.appId = appId;
        bufWin.title = title;
        bufWin.isFocused = isFocused;
        bufWin.isFloating = isFloating;
        bufWin.isUrgent = isUrgent;
        bufWin.layoutCol = pos[0];
        bufWin.layoutRow = pos[1];
        bufWin.tilePosX = tilePos[0];
        bufWin.tilePosY = tilePos[1];
        bufWin.width = size[0];
        bufWin.height = size[1];

        if (isFocused) {
            WindowStore.focusedWindowSlot = slot;
        }

        lastEventCollectionChanged = collectionChanged;
        return true;
    }

    function removeWindow(data) {
        if (!data || !data.id)
            return false;

        const slot = WindowStore.windowIdToSlot[data.id];
        if (slot === undefined)
            return false;

        WindowStore.windowBuffer[slot].valid = false;
        delete WindowStore.windowIdToSlot[data.id];

        if (WindowStore.focusedWindowSlot === slot) {
            WindowStore.focusedWindowSlot = -1;
        }

        lastEventCollectionChanged = true;
        return true;
    }

    function updateWindowFocus(data) {
        if (!data)
            return false;

        // Clear old focus
        if (WindowStore.focusedWindowSlot >= 0) {
            WindowStore.windowBuffer[WindowStore.focusedWindowSlot].isFocused = false;
        }

        if (data.id !== undefined && data.id !== null) {
            const slot = WindowStore.windowIdToSlot[data.id];
            if (slot !== undefined) {
                WindowStore.windowBuffer[slot].isFocused = true;
                WindowStore.focusedWindowSlot = slot;
                return true;
            }
            WindowStore.focusedWindowSlot = -1;
        } else {
            WindowStore.focusedWindowSlot = -1;
        }

        return true;
    }

    function updateWindowLayouts(data) {
        if (!data || !data.changes)
            return false;

        let changed = false;
        const changes = data.changes;

        for (let i = 0; i < changes.length; i++) {
            const id = changes[i][0];
            const layout = changes[i][1];
            const slot = WindowStore.windowIdToSlot[id];

            if (slot !== undefined) {
                const bufWin = WindowStore.windowBuffer[slot];
                const pos = layout.pos_in_scrolling_layout || [bufWin.layoutCol, bufWin.layoutRow];
                const tilePos = layout.tile_pos_in_workspace_view || [bufWin.tilePosX, bufWin.tilePosY];
                const size = layout.window_size || [bufWin.width, bufWin.height];

                if (bufWin.layoutCol !== pos[0] || bufWin.layoutRow !== pos[1] || bufWin.tilePosX !== tilePos[0] || bufWin.tilePosY !== tilePos[1] || bufWin.width !== size[0] || bufWin.height !== size[1]) {
                    bufWin.layoutCol = pos[0];
                    bufWin.layoutRow = pos[1];
                    bufWin.tilePosX = tilePos[0];
                    bufWin.tilePosY = tilePos[1];
                    bufWin.width = size[0];
                    bufWin.height = size[1];
                    lastEventCollectionChanged = true;
                    changed = true;
                }
            }
        }

        return changed;
    }
}
