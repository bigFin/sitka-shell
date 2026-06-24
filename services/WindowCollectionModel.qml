pragma Singleton
pragma ComponentBehavior: Bound

/*
 * WindowCollectionModel - derived UI collections for windows.
 *
 * WindowStore owns compositor state. This model commits reusable arrays and app
 * groups once per store batch so UI surfaces stop rebuilding the same grouping
 * structures inside render bindings.
 */

import QtQuick
import Quickshell
import "."

Singleton {
    id: root

    readonly property int storeVersion: WindowStore.version

    property var current: emptySnapshot()
    property var pending: null
    property int collectionSerial: 0

    readonly property var windows: current.windows
    readonly property var runningApps: current.runningApps
    readonly property var windowsByWorkspace: current.windowsByWorkspace
    readonly property var appGroupsByWorkspace: current.appGroupsByWorkspace

    onStoreVersionChanged: scheduleFromSources()

    Timer {
        id: commitTimer
        interval: 16
        repeat: false
        onTriggered: root.commitPending()
    }

    Component.onCompleted: scheduleFromSources()

    function scheduleFromSources(): void {
        pending = buildCurrentSnapshot();
        commitTimer.restart();
    }

    function commitPending(): void {
        if (!pending)
            return;

        if (sameWindowList(current.windows, pending.windows))
            return;

        current = pending;
        collectionSerial++;
    }

    function buildCurrentSnapshot(): var {
        const windowList = WindowStore.version > 0 ? WindowStore.getActiveWindows().map(windowFromStore).sort(sortWindows) : [];
        return buildSnapshot(windowList);
    }

    function buildSnapshot(windowList: var): var {
        const byWorkspace = {};
        const appGroupsByWs = {};
        const apps = {};

        for (let i = 0; i < windowList.length; i++) {
            const win = windowList[i];
            const workspaceId = String(win.workspace_id ?? "");
            const appId = win.app_id || win.title || "unknown";

            if (!byWorkspace[workspaceId])
                byWorkspace[workspaceId] = [];
            byWorkspace[workspaceId].push(win);

            if (!appGroupsByWs[workspaceId])
                appGroupsByWs[workspaceId] = {};
            if (!appGroupsByWs[workspaceId][appId])
                appGroupsByWs[workspaceId][appId] = newAppGroup(appId, win.workspace_id);
            appGroupsByWs[workspaceId][appId].windows.push(win);

            if (!apps[appId])
                apps[appId] = newRunningApp(appId, win);
            apps[appId].windows.push(win);
        }

        const groupedByWorkspace = {};
        for (const workspaceId in appGroupsByWs)
            groupedByWorkspace[workspaceId] = finaliseGroups(Object.values(appGroupsByWs[workspaceId]));

        return {
            windows: windowList,
            windowsByWorkspace: byWorkspace,
            appGroupsByWorkspace: groupedByWorkspace,
            runningApps: finaliseGroups(Object.values(apps))
        };
    }

    function newAppGroup(appId: string, workspaceId: var): var {
        return {
            id: appId,
            app_id: appId,
            workspace_id: workspaceId,
            title: appId,
            windows: [],
            count: 0,
            main: null
        };
    }

    function newRunningApp(appId: string, win: var): var {
        return {
            id: appId,
            app_id: appId,
            title: win.title || appId,
            windows: [],
            count: 0,
            main: null
        };
    }

    function finaliseGroups(groups: var): var {
        const result = groups.slice().sort((a, b) => String(a.id).localeCompare(String(b.id)));
        for (let i = 0; i < result.length; i++) {
            const group = result[i];
            group.windows = group.windows.slice().sort(sortWindows);
            group.count = group.windows.length;
            group.main = group.windows[0] || null;
            group.title = group.main?.title || group.title || group.id;
        }
        return result;
    }

    function windowFromStore(win: var): var {
        return {
            id: win.id,
            workspace_id: win.workspaceId,
            pid: win.pid,
            app_id: win.appId,
            initialClass: win.appId,
            initialTitle: win.title,
            title: win.title,
            is_focused: win.isFocused,
            is_floating: win.isFloating,
            is_urgent: win.isUrgent,
            layout: {
                pos_in_scrolling_layout: [win.layoutCol, win.layoutRow],
                tile_pos_in_workspace_view: win.tilePosX >= 0 && win.tilePosY >= 0 ? [win.tilePosX, win.tilePosY] : null,
                window_size: [win.width, win.height]
            }
        };
    }

    function sortWindows(a: var, b: var): int {
        const aPos = Array.isArray(a.layout?.pos_in_scrolling_layout) ? a.layout.pos_in_scrolling_layout : [0, 0];
        const bPos = Array.isArray(b.layout?.pos_in_scrolling_layout) ? b.layout.pos_in_scrolling_layout : [0, 0];
        if (String(a.workspace_id) !== String(b.workspace_id))
            return compareIds(a.workspace_id, b.workspace_id);
        if (aPos[0] !== bPos[0])
            return aPos[0] - bPos[0];
        if (aPos[1] !== bPos[1])
            return aPos[1] - bPos[1];
        return compareIds(a.id, b.id);
    }

    function compareIds(a: var, b: var): int {
        const aNum = Number(a);
        const bNum = Number(b);
        if (!Number.isNaN(aNum) && !Number.isNaN(bNum))
            return aNum - bNum;
        return String(a).localeCompare(String(b));
    }

    function sameWindowList(a: var, b: var): bool {
        if (a.length !== b.length)
            return false;

        for (let i = 0; i < a.length; i++) {
            const left = a[i];
            const right = b[i];
            const leftPos = Array.isArray(left.layout?.pos_in_scrolling_layout) ? left.layout.pos_in_scrolling_layout : [0, 0];
            const rightPos = Array.isArray(right.layout?.pos_in_scrolling_layout) ? right.layout.pos_in_scrolling_layout : [0, 0];
            const leftSize = Array.isArray(left.layout?.window_size) ? left.layout.window_size : [0, 0];
            const rightSize = Array.isArray(right.layout?.window_size) ? right.layout.window_size : [0, 0];

            if (left.id !== right.id
                    || left.workspace_id !== right.workspace_id
                    || left.app_id !== right.app_id
                    || left.pid !== right.pid
                    || left.title !== right.title
                    || left.is_focused !== right.is_focused
                    || left.is_floating !== right.is_floating
                    || left.is_urgent !== right.is_urgent
                    || leftPos[0] !== rightPos[0]
                    || leftPos[1] !== rightPos[1]
                    || leftSize[0] !== rightSize[0]
                    || leftSize[1] !== rightSize[1])
                return false;
        }
        return true;
    }

    function emptySnapshot(): var {
        return {
            windows: [],
            windowsByWorkspace: ({}),
            appGroupsByWorkspace: ({}),
            runningApps: []
        };
    }

    function getWindowsByWorkspaceId(workspaceId: var): var {
        return windowsByWorkspace[String(workspaceId)] || [];
    }

    function getWindowsByWorkspaceIndex(index: int): var {
        const workspace = WorkspaceModel.getWorkspaceByIndex(index);
        return workspace ? getWindowsByWorkspaceId(workspace.id) : [];
    }

    function getAppGroupsForWorkspaceId(workspaceId: var): var {
        return appGroupsByWorkspace[String(workspaceId)] || [];
    }
}
