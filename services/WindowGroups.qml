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

        const windows = WMService.getWindowsByWorkspaceId(workspaceId) || [];
        const groups = buildGroups(windows.filter(w => !!w));
        workspaceCache[key] = {
            version: version,
            groups: groups
        };
        return groups;
    }

    function getFocusedGroupIndex(workspaceId): int {
        const focusedId = Number(WMService.focusedWindowId);
        if (!Number.isFinite(focusedId))
            return -1;

        const groups = getGroupsForWorkspace(workspaceId);
        for (let i = 0; i < groups.length; i++) {
            const group = groups[i];
            if (!group)
                continue;

            if (groupIconsByApp) {
                const windows = group.windows || [];
                if (windows.some(w => Number(w?.id) === focusedId))
                    return i;
            } else if (Number(group.id) === focusedId) {
                return i;
            }
        }

        return -1;
    }

    function buildGroups(windows: var): var {
        if (groupIconsByApp && groupingRespectsLayout)
            return WMService.groupWindowsByLayoutAndId(windows);
        if (groupIconsByApp)
            return WMService.groupWindowsByApp(windows);

        return windows.map(w => ({
            app_id: w.app_id,
            id: w.id,
            title: w.title,
            windows: [w],
            count: 1,
            main: w
        }));
    }

    onGroupIconsByAppChanged: invalidateAll()
    onGroupingRespectsLayoutChanged: invalidateAll()

    Connections {
        target: WMService.isNiri ? Niri : null

        function onWindowsChanged(): void {
            root.invalidateAll();
        }

        function onFocusedWindowIdChanged(): void {
            root.version++;
        }
    }
}
