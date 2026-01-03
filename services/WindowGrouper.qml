pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "."

Singleton {
    id: grouper
    
    // ===== CONFIGURATION =====
    readonly property int maxGroups: 32
    readonly property int maxWindowsPerGroup: 8
    
    // ===== GROUP POOL =====
    property var groupPool: []
    
    // ===== STATE =====
    property int activeGroupCount: 0
    property int groupVersion: 0
    
    // Per-workspace group cache
    property var workspaceGroupCache: ({})  // { workspaceId: { version: n, groups: [slotIndices] } }
    
    // ===== PUBLIC API =====
    
    function getGroupsForWorkspace(workspaceId, forceRebuild) {
        const cache = workspaceGroupCache[workspaceId];
        
        // Return cached if valid and not forced
        if (cache && cache.version === WindowStore.version && !forceRebuild) {
            return cache.groups.map(slot => groupPool[slot]).filter(g => g.valid);
        }
        
        // Rebuild groups for this workspace
        rebuildGroupsForWorkspace(workspaceId);
        
        const newCache = workspaceGroupCache[workspaceId];
        return newCache ? newCache.groups.map(slot => groupPool[slot]).filter(g => g.valid) : [];
    }
    
    function getGroup(slot) {
        if (slot < 0 || slot >= maxGroups) return null;
        const group = groupPool[slot];
        return group.valid ? group : null;
    }
    
    function getWindowsInGroup(groupSlot) {
        if (groupSlot < 0 || groupSlot >= maxGroups) return [];
        const group = groupPool[groupSlot];
        if (!group.valid) return [];
        
        const result = [];
        for (let i = 0; i < group.windowSlots.length; i++) {
            const win = WindowStore.getWindow(group.windowSlots[i]);
            if (win) result.push(win);
        }
        return result;
    }
    
    function getPrimaryWindow(groupSlot) {
        if (groupSlot < 0 || groupSlot >= maxGroups) return null;
        const group = groupPool[groupSlot];
        if (!group.valid || group.primaryWindowSlot < 0) return null;
        return WindowStore.getWindow(group.primaryWindowSlot);
    }
    
    // ===== GROUPING STRATEGIES =====
    
    function rebuildGroupsForWorkspace(workspaceId) {
        // Get windows for this workspace from WindowStore
        const windows = WindowStore.getWindowsForWorkspace(workspaceId);
        
        // Sort by layout position (column, then row)
        windows.sort((a, b) => {
            if (a.layoutCol !== b.layoutCol) return a.layoutCol - b.layoutCol;
            return a.layoutRow - b.layoutRow;
        });
        
        // Reset groups we'll use
        let groupIdx = 0;
        const usedSlots = [];
        
        // Group by consecutive app_id (respects layout order)
        let currentAppId = null;
        let currentGroupSlot = -1;
        
        for (let i = 0; i < windows.length && groupIdx < maxGroups; i++) {
            const win = windows[i];
            const appId = win.appId || "unknown";
            
            // Start new group if app_id changes
            if (appId !== currentAppId) {
                currentGroupSlot = groupIdx++;
                const group = groupPool[currentGroupSlot];
                
                group.valid = true;
                group.appId = appId;
                group.windowSlots = [];
                group.count = 0;
                group.primaryWindowSlot = win.slot;
                group.workspaceId = workspaceId;
                
                currentAppId = appId;
                usedSlots.push(currentGroupSlot);
            }
            
            // Add window to current group
            if (currentGroupSlot >= 0 && groupPool[currentGroupSlot].count < maxWindowsPerGroup) {
                groupPool[currentGroupSlot].windowSlots.push(win.slot);
                groupPool[currentGroupSlot].count++;
            }
        }
        
        // Invalidate unused slots that were previously used for this workspace
        for (let i = 0; i < maxGroups; i++) {
            if (groupPool[i].workspaceId === workspaceId && !usedSlots.includes(i)) {
                groupPool[i].valid = false;
            }
        }
        
        // Update cache
        workspaceGroupCache[workspaceId] = {
            version: WindowStore.version,
            groups: usedSlots
        };
        
        activeGroupCount = usedSlots.length;
        groupVersion++;
    }
    
    function groupByAppOnly(workspaceId) {
        // Alternative grouping: merge all windows of same app regardless of layout position
        const windows = WindowStore.getWindowsForWorkspace(workspaceId);
        
        let groupIdx = 0;
        const appToGroupSlot = {};
        const usedSlots = [];
        
        for (let i = 0; i < windows.length; i++) {
            const win = windows[i];
            const appId = win.appId || "unknown";
            
            if (!(appId in appToGroupSlot)) {
                if (groupIdx >= maxGroups) break;
                
                const slot = groupIdx++;
                appToGroupSlot[appId] = slot;
                usedSlots.push(slot);
                
                const group = groupPool[slot];
                group.valid = true;
                group.appId = appId;
                group.windowSlots = [];
                group.count = 0;
                group.primaryWindowSlot = win.slot;
                group.workspaceId = workspaceId;
            }
            
            const slot = appToGroupSlot[appId];
            if (groupPool[slot].count < maxWindowsPerGroup) {
                groupPool[slot].windowSlots.push(win.slot);
                groupPool[slot].count++;
            }
        }
        
        return usedSlots.map(s => groupPool[s]);
    }
    
    // ===== UTILITY =====
    
    function invalidateWorkspaceCache(workspaceId) {
        delete workspaceGroupCache[workspaceId];
    }
    
    function invalidateAllCaches() {
        workspaceGroupCache = {};
    }
    
    Component.onCompleted: {
        // Initialize group pool once
        const pool = [];
        for (let i = 0; i < maxGroups; i++) {
            pool.push({
                slot: i,
                valid: false,
                appId: "",
                windowSlots: [],
                count: 0,
                primaryWindowSlot: -1,
                workspaceId: -1
            });
        }
        groupPool = pool;
        
        console.log("WindowGrouper: Pool initialized");
    }

    function debugDump() {
        console.log("WindowGrouper Debug:");
        console.log("  Active Groups:", activeGroupCount);
        console.log("  Group Version:", groupVersion);
        for (let i = 0; i < maxGroups; i++) {
            const g = groupPool[i];
            if (g.valid) {
                console.log(`  Group ${i}: ${g.appId} (${g.count} windows) ws=${g.workspaceId}`);
            }
        }
    }
}