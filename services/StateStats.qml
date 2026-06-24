pragma Singleton
pragma ComponentBehavior: Bound

/*
 * StateStats - IPC/debug snapshots for compositor state churn.
 *
 * This singleton intentionally has no UI. It exposes model/store counters over
 * IPC so focus/workspace switching can be audited without adding render work.
 */

import QtQuick
import Quickshell
import Quickshell.Io
import "."

Singleton {
    id: root

    property var baseline: null

    function ensureLoaded(): bool {
        return true;
    }

    function snapshotObject(): var {
        return {
            timestamp: new Date().toISOString(),
            windowStore: {
                version: WindowStore.version,
                activeWindowCount: WindowStore.activeWindowCount,
                activeWorkspaceCount: WindowStore.activeWorkspaceCount,
                focusedWindowSlot: WindowStore.focusedWindowSlot,
                focusedWorkspaceSlot: WindowStore.focusedWorkspaceSlot
            },
            activeWindow: {
                focusSerial: ActiveWindowModel.focusSerial,
                detailSerial: ActiveWindowModel.detailSerial,
                hasWindow: ActiveWindowModel.hasWindow,
                id: ActiveWindowModel.idString,
                appId: ActiveWindowModel.appId,
                title: ActiveWindowModel.title
            },
            workspace: {
                workspaceSerial: WorkspaceModel.workspaceSerial,
                focusedWorkspaceId: WorkspaceModel.focusedWorkspaceId,
                focusedWorkspaceIndex: WorkspaceModel.focusedWorkspaceIndex,
                focusedMonitorName: WorkspaceModel.focusedMonitorName,
                workspaceCount: WorkspaceModel.workspaceCount
            },
            windows: {
                collectionSerial: WindowCollectionModel.collectionSerial,
                count: WindowCollectionModel.windows.length,
                runningAppCount: WindowCollectionModel.runningApps.length
            },
            indicators: {
                targetSerial: WorkspaceIndicatorModel.targetSerial,
                activeWorkspaceId: WorkspaceIndicatorModel.activeWorkspaceId,
                focusedWindowId: WorkspaceIndicatorModel.focusedWindowId,
                focusedWindowWorkspaceId: WorkspaceIndicatorModel.focusedWindowWorkspaceId
            },
            stateMachine: {
                currentState: WMStateMachine.currentState,
                currentStateName: stateName(WMStateMachine.currentState),
                batchTimerRunning: WMStateMachine.batchTimerRunning,
                queueLength: WMStateMachine.eventQueue.length,
                maxQueueSize: WMStateMachine.maxQueueSize,
                oldestEventAgeMs: WMStateMachine.oldestEventAgeMs(),
                queuedEventCount: WMStateMachine.queuedEventCount,
                processedBatchCount: WMStateMachine.processedBatchCount,
                processedEventCount: WMStateMachine.processedEventCount,
                lastBatchSize: WMStateMachine.lastBatchSize,
                lastCoalescedSize: WMStateMachine.lastCoalescedSize,
                queuedByType: WMStateMachine.queuedByType,
                processedByType: WMStateMachine.processedByType,
                queuedByTypeNow: WMStateMachine.queuedByTypeNow()
            }
        };
    }

    function deltaObject(from: var, to: var): var {
        if (!from)
            return ({});

        return {
            windowStoreVersion: to.windowStore.version - from.windowStore.version,
            activeWindowFocusSerial: to.activeWindow.focusSerial - from.activeWindow.focusSerial,
            activeWindowDetailSerial: to.activeWindow.detailSerial - from.activeWindow.detailSerial,
            workspaceSerial: to.workspace.workspaceSerial - from.workspace.workspaceSerial,
            collectionSerial: to.windows.collectionSerial - from.windows.collectionSerial,
            indicatorTargetSerial: to.indicators.targetSerial - from.indicators.targetSerial,
            queueLength: to.stateMachine.queueLength - from.stateMachine.queueLength,
            queuedEventCount: to.stateMachine.queuedEventCount - from.stateMachine.queuedEventCount,
            processedBatchCount: to.stateMachine.processedBatchCount - from.stateMachine.processedBatchCount,
            processedEventCount: to.stateMachine.processedEventCount - from.stateMachine.processedEventCount
        };
    }

    function stateName(state: int): string {
        switch (state) {
        case WMStateMachine.stateIdle:
            return "idle";
        case WMStateMachine.stateCollecting:
            return "collecting";
        case WMStateMachine.stateProcessing:
            return "processing";
        case WMStateMachine.stateCommitting:
            return "committing";
        default:
            return "unknown";
        }
    }

    function toJson(value: var): string {
        return JSON.stringify(value, null, 2);
    }

    IpcHandler {
        target: "stateStats"

        function get(): string {
            return root.toJson(root.snapshotObject());
        }

        function mark(): string {
            root.baseline = root.snapshotObject();
            return root.toJson({
                marked: true,
                baseline: root.baseline
            });
        }

        function delta(): string {
            const current = root.snapshotObject();
            return root.toJson({
                hasBaseline: !!root.baseline,
                baseline: root.baseline,
                current: current,
                delta: root.deltaObject(root.baseline, current)
            });
        }

        function reset(): string {
            root.baseline = null;
            return root.toJson({
                reset: true
            });
        }
    }
}
