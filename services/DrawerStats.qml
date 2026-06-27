pragma Singleton
pragma ComponentBehavior: Bound

/*
 * DrawerStats - debug counters for drawer/popout state churn.
 *
 * UI components write small state transitions here; StateStats reads the
 * counters over IPC so drawer animation churn can be measured without adding
 * visible UI.
 */

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool dashboardVisible: false
    property bool dashboardExpanded: false
    property int dashboardCurrentTab: 0
    property bool dashboardFlashVisible: false
    property int dashboardStateSerial: 0
    property int dashboardFlashRequests: 0
    property int dashboardFlashAccepted: 0
    property int dashboardFlashCoalesced: 0
    property int dashboardFlashSuppressed: 0
    property int dashboardFlashHidden: 0

    property bool popoutHasCurrent: false
    property string popoutCurrentName: ""
    property string popoutDetachedMode: ""
    property string popoutQueuedMode: ""
    property int popoutStateSerial: 0
    property int popoutDetachCount: 0
    property int popoutCloseCount: 0

    function recordDashboardState(visible: bool, expanded: bool, currentTab: int, flashVisible: bool): void {
        if (dashboardVisible === visible && dashboardExpanded === expanded && dashboardCurrentTab === currentTab && dashboardFlashVisible === flashVisible)
            return;

        dashboardVisible = visible;
        dashboardExpanded = expanded;
        dashboardCurrentTab = currentTab;
        dashboardFlashVisible = flashVisible;
        dashboardStateSerial++;
    }

    function recordDashboardFlashRequest(): void {
        dashboardFlashRequests++;
    }

    function recordDashboardFlashAccepted(): void {
        dashboardFlashAccepted++;
    }

    function recordDashboardFlashCoalesced(): void {
        dashboardFlashCoalesced++;
    }

    function recordDashboardFlashSuppressed(): void {
        dashboardFlashSuppressed++;
    }

    function recordDashboardFlashHidden(): void {
        dashboardFlashHidden++;
    }

    function recordPopoutState(hasCurrent: bool, currentName: string, detachedMode: string, queuedMode: string): void {
        if (popoutHasCurrent === hasCurrent && popoutCurrentName === currentName && popoutDetachedMode === detachedMode && popoutQueuedMode === queuedMode)
            return;

        popoutHasCurrent = hasCurrent;
        popoutCurrentName = currentName;
        popoutDetachedMode = detachedMode;
        popoutQueuedMode = queuedMode;
        popoutStateSerial++;
    }

    function recordPopoutDetach(): void {
        popoutDetachCount++;
    }

    function recordPopoutClose(): void {
        popoutCloseCount++;
    }
}
