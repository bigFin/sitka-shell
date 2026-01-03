pragma Singleton
pragma ComponentBehavior: Bound

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
        if (eventQueue.length >= maxQueueSize) {
            console.warn("WMStateMachine: Event queue overflow, dropping oldest");
            eventQueue.shift();
        }
        
        eventQueue.push({ 
            type: eventType, 
            data: payload, 
            timestamp: Date.now() 
        });
        
        if (currentState === stateIdle) {
            currentState = stateCollecting;
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
        
        // Coalesce events
        const coalescedEvents = coalesceEvents(eventQueue);
        eventQueue = [];
        
        // Process each event
        let stateChanged = false;
        for (let i = 0; i < coalescedEvents.length; i++) {
            stateChanged = applyEvent(coalescedEvents[i]) || stateChanged;
        }
        
        // Commit changes
        currentState = stateCommitting;
        
        if (stateChanged) {
            WindowStore._rebuildWorkspaceWindowSlots();
            WindowStore._updateCounts();
            WindowStore._incrementVersion();
        }
        
        currentState = stateIdle;
    }
    
    function coalesceEvents(events) {
        // Group by event type, keeping all window open/close but latest of others
        const byType = {};
        const ordered = [];
        
        for (let i = 0; i < events.length; i++) {
            const event = events[i];
            const type = event.type;
            
            // Window open/close must be kept in order
            if (type === evtWindowOpened || type === evtWindowClosed) {
                ordered.push(event);
            } else {
                // Keep only the latest of each type
                byType[type] = event;
            }
        }
        
        // Add coalesced events
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
        if (!data || !data.workspaces) return false;
        
        let changed = false;
        const seenIds = {};
        const workspaces = data.workspaces;
        
        for (let i = 0; i < workspaces.length && i < WindowStore.maxWorkspaces; i++) {
            const ws = workspaces[i];
            const slot = WindowStore.workspaceBuffer[i];
            
            seenIds[ws.id] = true;
            
            // Check if anything changed
            if (!slot.valid || slot.id !== ws.id || slot.idx !== ws.idx ||
                slot.name !== (ws.name || "") || slot.output !== (ws.output || "") ||
                slot.isActive !== (ws.is_active || false) || 
                slot.isFocused !== (ws.is_focused || false)) {
                
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
                changed = true;
            }
        }
        
        return changed;
    }
    
    function updateWorkspaceActivation(data) {
        if (!data || !data.id) return false;
        
        const slot = WindowStore.workspaceIdToSlot[data.id];
        if (slot === undefined) return false;
        
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
        if (!data || !data.windows) return false;
        
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
                if (slot < 0) continue;
                WindowStore.windowIdToSlot[win.id] = slot;
            }
            
            const bufWin = WindowStore.windowBuffer[slot];
            const layout = win.layout || {};
            const pos = layout.pos_in_scrolling_layout || [0, 0];
            const size = layout.window_size || [0, 0];
            
            if (!bufWin.valid || bufWin.id !== win.id ||
                bufWin.workspaceId !== win.workspace_id ||
                bufWin.appId !== (win.app_id || "") ||
                bufWin.title !== (win.title || "") ||
                bufWin.isFocused !== (win.is_focused || false)) {
                
                bufWin.valid = true;
                bufWin.id = win.id;
                bufWin.workspaceId = win.workspace_id;
                bufWin.appId = win.app_id || "";
                bufWin.title = win.title || "";
                bufWin.isFocused = win.is_focused || false;
                bufWin.isFloating = win.is_floating || false;
                bufWin.layoutCol = pos[0];
                bufWin.layoutRow = pos[1];
                bufWin.width = size[0];
                bufWin.height = size[1];
                
                if (win.is_focused) {
                    WindowStore.focusedWindowSlot = slot;
                }
                
                changed = true;
            }
        }
        
        // Second pass: invalidate removed windows
        for (let i = 0; i < WindowStore.maxWindows; i++) {
            const bufWin = WindowStore.windowBuffer[i];
            if (bufWin.valid && !seenIds[bufWin.id]) {
                delete WindowStore.windowIdToSlot[bufWin.id];
                bufWin.valid = false;
                changed = true;
            }
        }
        
        return changed;
    }
    
    function addOrUpdateWindow(data) {
        if (!data || !data.window) return false;
        
        const win = data.window;
        let slot = WindowStore.windowIdToSlot[win.id];
        
        if (slot === undefined) {
            slot = WindowStore._allocateWindowSlot();
            if (slot < 0) return false;
            WindowStore.windowIdToSlot[win.id] = slot;
        }
        
        const bufWin = WindowStore.windowBuffer[slot];
        const layout = win.layout || {};
        const pos = layout.pos_in_scrolling_layout || [0, 0];
        const size = layout.window_size || [0, 0];
        
        bufWin.valid = true;
        bufWin.id = win.id;
        bufWin.workspaceId = win.workspace_id;
        bufWin.appId = win.app_id || "";
        bufWin.title = win.title || "";
        bufWin.isFocused = win.is_focused || false;
        bufWin.isFloating = win.is_floating || false;
        bufWin.layoutCol = pos[0];
        bufWin.layoutRow = pos[1];
        bufWin.width = size[0];
        bufWin.height = size[1];
        
        if (win.is_focused) {
            WindowStore.focusedWindowSlot = slot;
        }
        
        return true;
    }
    
    function removeWindow(data) {
        if (!data || !data.id) return false;
        
        const slot = WindowStore.windowIdToSlot[data.id];
        if (slot === undefined) return false;
        
        WindowStore.windowBuffer[slot].valid = false;
        delete WindowStore.windowIdToSlot[data.id];
        
        if (WindowStore.focusedWindowSlot === slot) {
            WindowStore.focusedWindowSlot = -1;
        }
        
        return true;
    }
    
    function updateWindowFocus(data) {
        if (!data) return false;
        
        // Clear old focus
        if (WindowStore.focusedWindowSlot >= 0) {
            WindowStore.windowBuffer[WindowStore.focusedWindowSlot].isFocused = false;
        }
        
        if (data.id) {
            const slot = WindowStore.windowIdToSlot[data.id];
            if (slot !== undefined) {
                WindowStore.windowBuffer[slot].isFocused = true;
                WindowStore.focusedWindowSlot = slot;
                return true;
            }
        } else {
            WindowStore.focusedWindowSlot = -1;
        }
        
        return true;
    }
    
    function updateWindowLayouts(data) {
        if (!data || !data.changes) return false;
        
        let changed = false;
        const changes = data.changes;
        
        for (let i = 0; i < changes.length; i++) {
            const id = changes[i][0];
            const layout = changes[i][1];
            const slot = WindowStore.windowIdToSlot[id];
            
            if (slot !== undefined) {
                const bufWin = WindowStore.windowBuffer[slot];
                const pos = layout.pos_in_scrolling_layout || [bufWin.layoutCol, bufWin.layoutRow];
                const size = layout.window_size || [bufWin.width, bufWin.height];
                
                if (bufWin.layoutCol !== pos[0] || bufWin.layoutRow !== pos[1] ||
                    bufWin.width !== size[0] || bufWin.height !== size[1]) {
                    bufWin.layoutCol = pos[0];
                    bufWin.layoutRow = pos[1];
                    bufWin.width = size[0];
                    bufWin.height = size[1];
                    changed = true;
                }
            }
        }
        
        return changed;
    }
}
