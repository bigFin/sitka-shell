pragma Singleton
pragma ComponentBehavior: Bound

import "../config"
import QtQuick
import Quickshell
import "."

Singleton {
    id: root

    property int version: 0
    property var workspaceCache: ({})

    readonly property bool groupIconsByApp: Config.bar.workspaces.groupIconsByApp
    readonly property bool groupingRespectsLayout: Config.bar.workspaces.groupingRespectsLayout
    readonly property bool storeReady: WindowStore.version > 0

    function invalidateAll(): void {
        workspaceCache = {};
        version++;
    }

    function getGroupsForWorkspace(workspaceId): var {
        if (workspaceId === undefined || workspaceId === null)
            return [];

        const key = String(workspaceId);
        const cached = workspaceCache[key];
        if (cached && cached.version === version)
            return cached.groups;

        const windows = getWindowsForWorkspace(workspaceId);
        const groups = buildGroups(windows.filter(w => !!w));
        workspaceCache[key] = {
            version: version,
            groups: groups
        };
        return groups;
    }

    function getFocusedGroupIndex(workspaceId): int {
        const focusedId = ActiveWindowModel.idString;
        if (!focusedId)
            return -1;

        const groups = getGroupsForWorkspace(workspaceId);
        for (let i = 0; i < groups.length; i++) {
            const group = groups[i];
            if (!group)
                continue;

            if (groupIconsByApp) {
                const windows = group.windows || [];
                if (windows.some(w => String(w?.id) === focusedId))
                    return i;
            } else if (String(group.id) === focusedId) {
                return i;
            }
        }

        return -1;
    }

    function getWindowsForWorkspace(workspaceId): var {
        return WindowCollectionModel.getWindowsByWorkspaceId(workspaceId) || [];
    }

    function buildGroups(windows: var): var {
        const sortedWindows = sortWindows(windows);
        if (groupIconsByApp && groupingRespectsLayout)
            return groupWindowsByLayoutAndId(sortedWindows);
        if (groupIconsByApp)
            return groupWindowsByApp(sortedWindows);

        return sortedWindows.map(w => ({
            app_id: w.app_id,
            id: w.id,
            title: w.title,
            windows: [w],
            count: 1,
            main: w
        }));
    }

    function sortWindows(windows: var): var {
        return windows.slice().sort((a, b) => {
            const aPos = Array.isArray(a.layout?.pos_in_scrolling_layout) ? a.layout.pos_in_scrolling_layout : [0, 0];
            const bPos = Array.isArray(b.layout?.pos_in_scrolling_layout) ? b.layout.pos_in_scrolling_layout : [0, 0];
            if (aPos[0] !== bPos[0])
                return aPos[0] - bPos[0];
            return aPos[1] - bPos[1];
        });
    }

    function groupWindowsByApp(windows: var): var {
        const groups = {};
        for (let i = 0; i < windows.length; i++) {
            const w = windows[i];
            const appId = w.app_id || "unknown";
            if (!groups[appId]) {
                groups[appId] = {
                    app_id: appId,
                    id: w.id,
                    title: w.title,
                    windows: []
                };
            }
            groups[appId].windows.push(w);
        }

        const result = [];
        for (const key in groups) {
            const group = groups[key];
            group.count = group.windows.length;
            group.main = group.windows[0];
            result.push(group);
        }
        return result;
    }

    function groupWindowsByLayoutAndId(windows: var): var {
        const groups = [];
        let currentGroup = null;

        for (let i = 0; i < windows.length; i++) {
            const w = windows[i];
            if (!currentGroup || currentGroup.app_id !== w.app_id) {
                currentGroup = {
                    app_id: w.app_id,
                    id: w.id,
                    title: w.title,
                    windows: [w],
                    count: 1,
                    main: w
                };
                groups.push(currentGroup);
            } else {
                currentGroup.windows.push(w);
                currentGroup.count = currentGroup.windows.length;
            }
        }

        return groups;
    }

    onGroupIconsByAppChanged: invalidateAll()
    onGroupingRespectsLayoutChanged: invalidateAll()

    Connections {
        target: WindowStore

        function onVersionChanged(): void {
            root.invalidateAll();
        }
    }
}
