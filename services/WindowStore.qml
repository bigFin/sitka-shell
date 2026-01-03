pragma Singleton
pragma ComponentBehavior: Bound

/*
 * WindowStore - Static Buffer Store for Window/Workspace Data
 * 
 * This singleton provides pre-allocated static buffers for workspaces and windows,
 * avoiding dynamic allocation and reducing GC pressure.
 * 
 * Key concepts:
 * - Buffers are fixed-size arrays (10 workspaces, 64 windows)
 * - Each slot has a 'valid' flag indicating if it's in use
 * - The 'version' property increments only when state actually changes
 * - UI components should watch 'version' for efficient updates
 * 
 * Usage example:
 *   readonly property int storeVersion: WindowStore.version
 *   readonly property var myData: {
 *       void storeVersion;  // Depend on version
 *       return WindowStore.getWindowsForWorkspace(wsId);
 *   }
 * 
 * Public API:
 * - getWorkspace(slotOrId) - Get workspace by slot index or ID
 * - getWindow(slotOrId) - Get window by slot index or ID  
 * - getWindowsForWorkspace(workspaceId) - Get all windows for a workspace
 * - getFocusedWorkspace() / getFocusedWindow() - Get focused items
 * - version - Increments when state changes (watch this for updates)
 */

import QtQuick
import Quickshell

Singleton {
    id: store
    
    // ===== STATIC BUFFER CONFIGURATION =====
    readonly property int maxWorkspaces: 10
    readonly property int maxWindows: 64
    readonly property int maxWindowsPerWorkspace: 16
    
    // ===== VERSION COUNTER (Triggers UI Updates) =====
    // UI components watch this - only incremented when state actually changes
    property int version: 0
    
    // ===== PRE-ALLOCATED WORKSPACE BUFFER =====
    property var workspaceBuffer: []
    
    // ===== PRE-ALLOCATED WINDOW BUFFER =====
    property var windowBuffer: []
    
    // ===== DERIVED COUNTS =====
    property int activeWorkspaceCount: 0
    property int activeWindowCount: 0
    property int focusedWorkspaceSlot: -1
    property int focusedWindowSlot: -1
    
    // ===== LOOKUP TABLES (O(1) access) =====
    property var windowIdToSlot: ({})
    property var workspaceIdToSlot: ({})
    property var workspaceWindowSlots: ({})  // { workspaceId: [slotIdx, ...] }
    
    // ===== PUBLIC API =====
    
    function getWorkspace(slotOrId) {
        let slot;
        if (typeof slotOrId === 'number' && slotOrId < maxWorkspaces && slotOrId >= 0) {
            slot = slotOrId;
        } else {
            slot = workspaceIdToSlot[slotOrId];
        }
        if (slot === undefined || slot < 0 || slot >= maxWorkspaces) return null;
        const ws = workspaceBuffer[slot];
        return ws.valid ? ws : null;
    }
    
    function getWindow(slotOrId) {
        let slot;
        if (typeof slotOrId === 'number' && slotOrId < maxWindows && slotOrId >= 0) {
            slot = slotOrId;
        } else {
            slot = windowIdToSlot[slotOrId];
        }
        if (slot === undefined || slot < 0 || slot >= maxWindows) return null;
        const win = windowBuffer[slot];
        return win.valid ? win : null;
    }
    
    function getWindowsForWorkspace(workspaceId) {
        const slots = workspaceWindowSlots[workspaceId] || [];
        const result = [];
        for (let i = 0; i < slots.length; i++) {
            const win = windowBuffer[slots[i]];
            if (win && win.valid) {
                result.push(win);
            }
        }
        return result;
    }
    
    function getWindowCountForWorkspace(workspaceId) {
        const slots = workspaceWindowSlots[workspaceId];
        return slots ? slots.length : 0;
    }
    
    function getFocusedWorkspace() {
        if (focusedWorkspaceSlot < 0 || focusedWorkspaceSlot >= maxWorkspaces) return null;
        const ws = workspaceBuffer[focusedWorkspaceSlot];
        return ws.valid ? ws : null;
    }
    
    function getFocusedWindow() {
        if (focusedWindowSlot < 0 || focusedWindowSlot >= maxWindows) return null;
        const win = windowBuffer[focusedWindowSlot];
        return win.valid ? win : null;
    }
    
    function getActiveWorkspaces() {
        const result = [];
        for (let i = 0; i < maxWorkspaces; i++) {
            if (workspaceBuffer[i].valid) {
                result.push(workspaceBuffer[i]);
            }
        }
        return result;
    }
    
    function getActiveWindows() {
        const result = [];
        for (let i = 0; i < maxWindows; i++) {
            if (windowBuffer[i].valid) {
                result.push(windowBuffer[i]);
            }
        }
        return result;
    }
    
    function hasWindowsOnWorkspace(workspaceId) {
        const slots = workspaceWindowSlots[workspaceId];
        return slots && slots.length > 0;
    }
    
    // ===== INTERNAL UPDATE METHODS (Called by WMStateMachine) =====
    
    function _allocateWindowSlot() {
        for (let i = 0; i < maxWindows; i++) {
            if (!windowBuffer[i].valid) {
                return i;
            }
        }
        console.warn("WindowStore: No free window slots!");
        return -1;
    }
    
    function _allocateWorkspaceSlot() {
        for (let i = 0; i < maxWorkspaces; i++) {
            if (!workspaceBuffer[i].valid) {
                return i;
            }
        }
        console.warn("WindowStore: No free workspace slots!");
        return -1;
    }
    
    function _rebuildWorkspaceWindowSlots() {
        const newSlots = {};
        for (let i = 0; i < maxWindows; i++) {
            const win = windowBuffer[i];
            if (win.valid && win.workspaceId >= 0) {
                if (!newSlots[win.workspaceId]) {
                    newSlots[win.workspaceId] = [];
                }
                newSlots[win.workspaceId].push(i);
            }
        }
        workspaceWindowSlots = newSlots;
    }
    
    function _updateCounts() {
        let wsCount = 0;
        let winCount = 0;
        for (let i = 0; i < maxWorkspaces; i++) {
            if (workspaceBuffer[i].valid) wsCount++;
        }
        for (let i = 0; i < maxWindows; i++) {
            if (windowBuffer[i].valid) winCount++;
        }
        activeWorkspaceCount = wsCount;
        activeWindowCount = winCount;
    }
    
    function _incrementVersion() {
        version++;
    }

    Component.onCompleted: {
        // Initialize workspace buffer once
        const wsBuffer = [];
        for (let i = 0; i < maxWorkspaces; i++) {
            wsBuffer.push({
                slot: i,
                valid: false,
                id: -1,
                idx: -1,
                name: "",
                output: "",
                isActive: false,
                isFocused: false,
                windowCount: 0
            });
        }
        workspaceBuffer = wsBuffer;

        // Initialize window buffer once
        const winBuffer = [];
        for (let i = 0; i < maxWindows; i++) {
            winBuffer.push({
                slot: i,
                valid: false,
                id: -1,
                workspaceId: -1,
                appId: "",
                title: "",
                isFocused: false,
                isFloating: false,
                layoutCol: 0,
                layoutRow: 0,
                width: 0,
                height: 0,
                posX: 0,
                posY: 0
            });
        }
        windowBuffer = winBuffer;

        // console.log("WindowStore: Buffers initialized");
    }

    // ===== DEBUG =====
    function debugDump() {
        // console.log("WindowStore Debug Dump:");
        // console.log("  Version:", version);
        // console.log("  Active Workspaces:", activeWorkspaceCount);
        // console.log("  Active Windows:", activeWindowCount);
        // console.log("  Focused Workspace Slot:", focusedWorkspaceSlot);
        // console.log("  Focused Window Slot:", focusedWindowSlot);
    }
}