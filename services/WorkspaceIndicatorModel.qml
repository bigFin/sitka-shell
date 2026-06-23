pragma Singleton
pragma ComponentBehavior: Bound

/*
 * WorkspaceIndicatorModel - committed visual targets for workspace indicators.
 *
 * WorkspaceModel, ActiveWindowModel, and WindowCollectionModel describe state.
 * This model derives stable target identities for visual indicators so QML
 * geometry code can measure delegates without also deciding which compositor
 * state is current.
 */

import QtQuick
import Quickshell
import "."

Singleton {
    id: root

    readonly property int workspaceSerial: WorkspaceModel.workspaceSerial
    readonly property int focusSerial: ActiveWindowModel.focusSerial
    readonly property int collectionSerial: WindowCollectionModel.collectionSerial

    property var current: emptyTargets()
    property var pending: null
    property int targetSerial: 0

    readonly property string activeWorkspaceId: current.activeWorkspaceId
    readonly property string focusedWindowId: current.focusedWindowId
    readonly property string focusedWindowWorkspaceId: current.focusedWindowWorkspaceId
    readonly property var activeWorkspaceByOutput: current.activeWorkspaceByOutput
    readonly property var focusedWindowByOutput: current.focusedWindowByOutput

    onWorkspaceSerialChanged: scheduleFromSources()
    onFocusSerialChanged: scheduleFromSources()
    onCollectionSerialChanged: scheduleFromSources()

    Timer {
        id: commitTimer
        interval: 16
        repeat: false
        onTriggered: root.commitPending()
    }

    Component.onCompleted: scheduleFromSources()

    function scheduleFromSources(): void {
        pending = buildTargets();
        commitTimer.restart();
    }

    function commitPending(): void {
        if (!pending)
            return;

        if (sameTargets(current, pending))
            return;

        current = pending;
        targetSerial++;
    }

    function buildTargets(): var {
        const activeByOutput = {};
        const focusedByOutput = {};
        const focusedWorkspaceId = findFocusedWindowWorkspaceId();

        const workspaces = WorkspaceModel.allWorkspaces || [];
        for (let i = 0; i < workspaces.length; i++) {
            const ws = workspaces[i];
            const output = ws.output || "";
            if (!output)
                continue;

            if (ws.is_active || ws.is_focused || String(ws.id) === WorkspaceModel.focusedWorkspaceId) {
                activeByOutput[output] = {
                    workspaceId: String(ws.id),
                    workspaceIdx: ws.idx,
                    output: output
                };
            }

            if (focusedWorkspaceId && String(ws.id) === focusedWorkspaceId) {
                focusedByOutput[output] = {
                    workspaceId: focusedWorkspaceId,
                    windowId: ActiveWindowModel.idString,
                    output: output
                };
            }
        }

        return {
            activeWorkspaceId: WorkspaceModel.focusedWorkspaceId,
            focusedWindowId: ActiveWindowModel.idString,
            focusedWindowWorkspaceId: focusedWorkspaceId,
            activeWorkspaceByOutput: activeByOutput,
            focusedWindowByOutput: focusedByOutput
        };
    }

    function findFocusedWindowWorkspaceId(): string {
        if (!ActiveWindowModel.hasWindow)
            return "";

        const win = ActiveWindowModel.window;
        if (win?.workspaceId !== undefined && win?.workspaceId !== null)
            return String(win.workspaceId);
        if (win?.workspace_id !== undefined && win?.workspace_id !== null)
            return String(win.workspace_id);

        const windows = WindowCollectionModel.windows || [];
        for (let i = 0; i < windows.length; i++) {
            if (String(windows[i].id) === ActiveWindowModel.idString)
                return String(windows[i].workspace_id);
        }
        return "";
    }

    function getTargetsForOutput(outputName: string): var {
        return {
            active: activeWorkspaceByOutput[outputName] || null,
            focusedWindow: focusedWindowByOutput[outputName] || null
        };
    }

    function emptyTargets(): var {
        return {
            activeWorkspaceId: "",
            focusedWindowId: "",
            focusedWindowWorkspaceId: "",
            activeWorkspaceByOutput: ({}),
            focusedWindowByOutput: ({})
        };
    }

    function sameTargets(a: var, b: var): bool {
        return a.activeWorkspaceId === b.activeWorkspaceId
            && a.focusedWindowId === b.focusedWindowId
            && a.focusedWindowWorkspaceId === b.focusedWindowWorkspaceId
            && sameMap(a.activeWorkspaceByOutput, b.activeWorkspaceByOutput)
            && sameMap(a.focusedWindowByOutput, b.focusedWindowByOutput);
    }

    function sameMap(a: var, b: var): bool {
        const aKeys = Object.keys(a);
        const bKeys = Object.keys(b);
        if (aKeys.length !== bKeys.length)
            return false;

        for (let i = 0; i < aKeys.length; i++) {
            const key = aKeys[i];
            const left = a[key];
            const right = b[key];
            if (!right
                    || left.workspaceId !== right.workspaceId
                    || left.windowId !== right.windowId
                    || left.workspaceIdx !== right.workspaceIdx
                    || left.output !== right.output)
                return false;
        }
        return true;
    }
}
