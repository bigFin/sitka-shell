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
                workspaceVersion: WindowStore.workspaceVersion,
                collectionVersion: WindowStore.collectionVersion,
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
            systemUsage: {
                refCount: SystemUsage.refCount,
                domainRefCount: SystemUsage.domainRefCount,
                legacyRefCount: SystemUsage.legacyRefCount,
                cpuRefCount: SystemUsage.cpuRefCount,
                memoryRefCount: SystemUsage.memoryRefCount,
                storageRefCount: SystemUsage.storageRefCount,
                gpuRefCount: SystemUsage.gpuRefCount,
                sensorRefCount: SystemUsage.sensorRefCount,
                cpuActive: SystemUsage.cpuActive,
                memoryActive: SystemUsage.memoryActive,
                storageActive: SystemUsage.storageActive,
                gpuActive: SystemUsage.gpuActive,
                sensorActive: SystemUsage.sensorActive,
                cpuSerial: SystemUsage.cpuSerial,
                memorySerial: SystemUsage.memorySerial,
                storageSerial: SystemUsage.storageSerial,
                gpuSerial: SystemUsage.gpuSerial,
                sensorSerial: SystemUsage.sensorSerial,
                cpuPollCount: SystemUsage.cpuPollCount,
                memoryPollCount: SystemUsage.memoryPollCount,
                storagePollCount: SystemUsage.storagePollCount,
                gpuPollCount: SystemUsage.gpuPollCount,
                sensorPollCount: SystemUsage.sensorPollCount
            },
            sysMonitor: {
                refCount: SysMonitorService.refCount,
                domainRefCount: SysMonitorService.domainRefCount,
                legacyRefCount: SysMonitorService.legacyRefCount,
                metricsRefCount: SysMonitorService.metricsRefCount,
                processRefCount: SysMonitorService.processRefCount,
                systemRefCount: SysMonitorService.systemRefCount,
                gpuRefCount: SysMonitorService.gpuRefCount,
                metricsActive: SysMonitorService.metricsActive,
                processesActive: SysMonitorService.processesActive,
                systemActive: SysMonitorService.systemActive,
                gpuActive: SysMonitorService.gpuActive,
                isUpdating: SysMonitorService.isUpdating,
                metricsSerial: SysMonitorService.metricsSerial,
                processSerial: SysMonitorService.processSerial,
                systemSerial: SysMonitorService.systemSerial,
                gpuSerial: SysMonitorService.gpuSerial,
                metricsPollCount: SysMonitorService.metricsPollCount,
                processPollCount: SysMonitorService.processPollCount,
                systemPollCount: SysMonitorService.systemPollCount,
                gpuPollCount: SysMonitorService.gpuPollCount,
                processCount: SysMonitorService.processes.length,
                gpuCount: SysMonitorService.gpus.length
            },
            drawers: {
                dashboardVisible: DrawerStats.dashboardVisible,
                dashboardExpanded: DrawerStats.dashboardExpanded,
                dashboardCurrentTab: DrawerStats.dashboardCurrentTab,
                dashboardFlashVisible: DrawerStats.dashboardFlashVisible,
                dashboardStateSerial: DrawerStats.dashboardStateSerial,
                dashboardFlashRequests: DrawerStats.dashboardFlashRequests,
                dashboardFlashAccepted: DrawerStats.dashboardFlashAccepted,
                dashboardFlashCoalesced: DrawerStats.dashboardFlashCoalesced,
                dashboardFlashSuppressed: DrawerStats.dashboardFlashSuppressed,
                dashboardFlashHidden: DrawerStats.dashboardFlashHidden,
                popoutHasCurrent: DrawerStats.popoutHasCurrent,
                popoutCurrentName: DrawerStats.popoutCurrentName,
                popoutDetachedMode: DrawerStats.popoutDetachedMode,
                popoutQueuedMode: DrawerStats.popoutQueuedMode,
                popoutStateSerial: DrawerStats.popoutStateSerial,
                popoutDetachCount: DrawerStats.popoutDetachCount,
                popoutCloseCount: DrawerStats.popoutCloseCount
            },
            stateMachine: {
                currentState: WMStateMachine.currentState,
                currentStateName: stateName(WMStateMachine.currentState),
                batchTimerRunning: WMStateMachine.batchTimerRunning,
                queueLength: WMStateMachine.eventQueue.length,
                maxQueueSize: WMStateMachine.maxQueueSize,
                oldestEventAgeMs: WMStateMachine.oldestEventAgeMs(),
                queuedEventCount: WMStateMachine.queuedEventCount,
                skippedEventCount: WMStateMachine.skippedEventCount,
                quietTitleUpdateCount: WMStateMachine.quietTitleUpdateCount,
                processedBatchCount: WMStateMachine.processedBatchCount,
                processedEventCount: WMStateMachine.processedEventCount,
                lastBatchSize: WMStateMachine.lastBatchSize,
                lastCoalescedSize: WMStateMachine.lastCoalescedSize,
                queuedByType: WMStateMachine.queuedByType,
                skippedByType: WMStateMachine.skippedByType,
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
            windowStoreWorkspaceVersion: to.windowStore.workspaceVersion - from.windowStore.workspaceVersion,
            windowStoreCollectionVersion: to.windowStore.collectionVersion - from.windowStore.collectionVersion,
            activeWindowFocusSerial: to.activeWindow.focusSerial - from.activeWindow.focusSerial,
            activeWindowDetailSerial: to.activeWindow.detailSerial - from.activeWindow.detailSerial,
            workspaceSerial: to.workspace.workspaceSerial - from.workspace.workspaceSerial,
            collectionSerial: to.windows.collectionSerial - from.windows.collectionSerial,
            indicatorTargetSerial: to.indicators.targetSerial - from.indicators.targetSerial,
            systemUsageCpuSerial: to.systemUsage.cpuSerial - from.systemUsage.cpuSerial,
            systemUsageMemorySerial: to.systemUsage.memorySerial - from.systemUsage.memorySerial,
            systemUsageStorageSerial: to.systemUsage.storageSerial - from.systemUsage.storageSerial,
            systemUsageGpuSerial: to.systemUsage.gpuSerial - from.systemUsage.gpuSerial,
            systemUsageSensorSerial: to.systemUsage.sensorSerial - from.systemUsage.sensorSerial,
            systemUsageCpuPollCount: to.systemUsage.cpuPollCount - from.systemUsage.cpuPollCount,
            systemUsageMemoryPollCount: to.systemUsage.memoryPollCount - from.systemUsage.memoryPollCount,
            systemUsageStoragePollCount: to.systemUsage.storagePollCount - from.systemUsage.storagePollCount,
            systemUsageGpuPollCount: to.systemUsage.gpuPollCount - from.systemUsage.gpuPollCount,
            systemUsageSensorPollCount: to.systemUsage.sensorPollCount - from.systemUsage.sensorPollCount,
            sysMonitorMetricsSerial: to.sysMonitor.metricsSerial - from.sysMonitor.metricsSerial,
            sysMonitorProcessSerial: to.sysMonitor.processSerial - from.sysMonitor.processSerial,
            sysMonitorSystemSerial: to.sysMonitor.systemSerial - from.sysMonitor.systemSerial,
            sysMonitorGpuSerial: to.sysMonitor.gpuSerial - from.sysMonitor.gpuSerial,
            sysMonitorMetricsPollCount: to.sysMonitor.metricsPollCount - from.sysMonitor.metricsPollCount,
            sysMonitorProcessPollCount: to.sysMonitor.processPollCount - from.sysMonitor.processPollCount,
            sysMonitorSystemPollCount: to.sysMonitor.systemPollCount - from.sysMonitor.systemPollCount,
            sysMonitorGpuPollCount: to.sysMonitor.gpuPollCount - from.sysMonitor.gpuPollCount,
            dashboardStateSerial: to.drawers.dashboardStateSerial - from.drawers.dashboardStateSerial,
            dashboardFlashRequests: to.drawers.dashboardFlashRequests - from.drawers.dashboardFlashRequests,
            dashboardFlashAccepted: to.drawers.dashboardFlashAccepted - from.drawers.dashboardFlashAccepted,
            dashboardFlashCoalesced: to.drawers.dashboardFlashCoalesced - from.drawers.dashboardFlashCoalesced,
            dashboardFlashSuppressed: to.drawers.dashboardFlashSuppressed - from.drawers.dashboardFlashSuppressed,
            dashboardFlashHidden: to.drawers.dashboardFlashHidden - from.drawers.dashboardFlashHidden,
            popoutStateSerial: to.drawers.popoutStateSerial - from.drawers.popoutStateSerial,
            popoutDetachCount: to.drawers.popoutDetachCount - from.drawers.popoutDetachCount,
            popoutCloseCount: to.drawers.popoutCloseCount - from.drawers.popoutCloseCount,
            queueLength: to.stateMachine.queueLength - from.stateMachine.queueLength,
            queuedEventCount: to.stateMachine.queuedEventCount - from.stateMachine.queuedEventCount,
            skippedEventCount: to.stateMachine.skippedEventCount - from.stateMachine.skippedEventCount,
            quietTitleUpdateCount: to.stateMachine.quietTitleUpdateCount - from.stateMachine.quietTitleUpdateCount,
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
