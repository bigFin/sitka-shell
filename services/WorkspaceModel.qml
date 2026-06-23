pragma Singleton
pragma ComponentBehavior: Bound

/*
 * WorkspaceModel - derived UI model for workspace display state.
 *
 * Compositor events update WindowStore. This model commits a single workspace
 * snapshot for UI components so workspace lists, active indexes, names, and
 * occupancy update together instead of each surface binding to raw Niri state.
 */

import QtQuick
import Quickshell
import "."

Singleton {
    id: root

    readonly property int storeVersion: WindowStore.version

    property var current: emptySnapshot()
    property int workspaceSerial: 0
    property var pending: null

    readonly property var allWorkspaces: current.allWorkspaces
    readonly property var currentOutputWorkspaces: current.currentOutputWorkspaces
    readonly property var workspaceHasWindows: current.workspaceHasWindows
    readonly property string focusedWorkspaceId: current.focusedWorkspaceId
    readonly property int focusedWorkspaceIndex: current.focusedWorkspaceIndex
    readonly property string focusedMonitorName: current.focusedMonitorName
    readonly property int workspaceCount: current.workspaceCount
    readonly property var focusedWorkspace: current.focusedWorkspace

    onStoreVersionChanged: scheduleFromSources()

    Connections {
        target: Niri

        function onAllWorkspacesChanged(): void {
            if (WindowStore.version === 0)
                root.scheduleFromSources();
        }

        function onFocusedWorkspaceIdChanged(): void {
            if (WindowStore.version === 0)
                root.scheduleFromSources();
        }

        function onFocusedWorkspaceIndexChanged(): void {
            if (WindowStore.version === 0)
                root.scheduleFromSources();
        }

        function onFocusedMonitorNameChanged(): void {
            if (WindowStore.version === 0)
                root.scheduleFromSources();
        }

        function onCurrentOutputWorkspacesChanged(): void {
            if (WindowStore.version === 0)
                root.scheduleFromSources();
        }

        function onWorkspaceHasWindowsChanged(): void {
            if (WindowStore.version === 0)
                root.scheduleFromSources();
        }
    }

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

        if (sameSnapshot(current, pending))
            return;

        current = pending;
        workspaceSerial++;
    }

    function buildCurrentSnapshot(): var {
        if (WindowStore.version > 0)
            return snapshotFromStore();

        if (WMDetector.isNiri)
            return snapshotFromLegacyNiri();

        return emptySnapshot();
    }

    function snapshotFromStore(): var {
        const workspaces = WindowStore.getActiveWorkspaces().map(workspaceFromStore).sort((a, b) => a.idx - b.idx);
        let focused = WindowStore.getFocusedWorkspace();
        if (!focused)
            focused = workspaces.find(w => w.is_focused) || workspaces.find(w => w.is_active) || null;
        else
            focused = workspaceFromStore(focused);

        return buildSnapshot(workspaces, focused, buildOccupancy(workspaces));
    }

    function snapshotFromLegacyNiri(): var {
        const workspaces = (Niri.allWorkspaces || []).slice().sort((a, b) => a.idx - b.idx);
        const focused = workspaces.find(w => String(w.id) === String(Niri.focusedWorkspaceId))
            || workspaces[Niri.focusedWorkspaceIndex]
            || workspaces.find(w => w.is_focused)
            || workspaces.find(w => w.is_active)
            || null;

        return buildSnapshot(workspaces, focused, Niri.workspaceHasWindows || ({}));
    }

    function buildSnapshot(workspaces: var, focused: var, occupied: var): var {
        const focusedId = focused ? String(focused.id) : "";
        const focusedIndex = focused ? workspaces.findIndex(w => String(w.id) === focusedId) : -1;
        const monitorName = focused?.output || "";
        const outputWorkspaces = monitorName ? workspaces.filter(w => w.output === monitorName) : workspaces;

        return {
            allWorkspaces: workspaces,
            currentOutputWorkspaces: outputWorkspaces,
            workspaceHasWindows: occupied,
            focusedWorkspaceId: focusedId,
            focusedWorkspaceIndex: Math.max(0, focusedIndex),
            focusedMonitorName: monitorName,
            workspaceCount: workspaces.length,
            focusedWorkspace: focused
        };
    }

    function workspaceFromStore(ws: var): var {
        return {
            id: ws.id,
            idx: ws.idx,
            name: ws.name || "",
            output: ws.output || "",
            is_active: ws.isActive,
            is_focused: ws.isFocused,
            windowCount: WindowStore.getWindowCountForWorkspace(ws.id)
        };
    }

    function buildOccupancy(workspaces: var): var {
        const occupied = {};
        for (let i = 0; i < workspaces.length; i++) {
            const ws = workspaces[i];
            occupied[ws.idx] = WindowStore.hasWindowsOnWorkspace(ws.id);
        }
        return occupied;
    }

    function emptySnapshot(): var {
        return {
            allWorkspaces: [],
            currentOutputWorkspaces: [],
            workspaceHasWindows: ({}),
            focusedWorkspaceId: "",
            focusedWorkspaceIndex: 0,
            focusedMonitorName: "",
            workspaceCount: 0,
            focusedWorkspace: null
        };
    }

    function sameSnapshot(a: var, b: var): bool {
        return a.focusedWorkspaceId === b.focusedWorkspaceId
            && a.focusedWorkspaceIndex === b.focusedWorkspaceIndex
            && a.focusedMonitorName === b.focusedMonitorName
            && sameWorkspaceList(a.allWorkspaces, b.allWorkspaces)
            && sameOccupancy(a.workspaceHasWindows, b.workspaceHasWindows);
    }

    function sameWorkspaceList(a: var, b: var): bool {
        if (a.length !== b.length)
            return false;

        for (let i = 0; i < a.length; i++) {
            const left = a[i];
            const right = b[i];
            if (left.id !== right.id
                    || left.idx !== right.idx
                    || left.name !== right.name
                    || left.output !== right.output
                    || left.is_active !== right.is_active
                    || left.is_focused !== right.is_focused
                    || left.windowCount !== right.windowCount)
                return false;
        }
        return true;
    }

    function sameOccupancy(a: var, b: var): bool {
        const aKeys = Object.keys(a);
        const bKeys = Object.keys(b);
        if (aKeys.length !== bKeys.length)
            return false;

        for (let i = 0; i < aKeys.length; i++) {
            const key = aKeys[i];
            if (a[key] !== b[key])
                return false;
        }
        return true;
    }

    function getWorkspacesForOutput(outputName: string): var {
        if (!outputName)
            return allWorkspaces;
        return allWorkspaces.filter(w => w && w.output === outputName);
    }

    function getActiveIndexForOutput(outputName: string): int {
        const workspaces = getWorkspacesForOutput(outputName);
        return workspaces.findIndex(w => String(w.id) === focusedWorkspaceId);
    }

    function getWorkspaceNameByIndex(index: int): string {
        if (index < 0 || index >= allWorkspaces.length)
            return "";
        return allWorkspaces[index].name || "";
    }

    function getWorkspaceNameById(id: var): string {
        const ws = allWorkspaces.find(w => String(w.id) === String(id));
        return ws?.name ?? "";
    }

    function getWorkspaceByIndex(index: int): var {
        if (index < 0 || index >= allWorkspaces.length)
            return null;
        return allWorkspaces[index];
    }
}
