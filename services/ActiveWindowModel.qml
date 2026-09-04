pragma Singleton
pragma ComponentBehavior: Bound

/*
 * ActiveWindowModel - derived UI model for focused-window display state.
 *
 * Window manager events update WindowStore. This model commits one stable
 * display snapshot per batch and gives visual components a single focus serial
 * to react to, instead of binding title, class, and id independently.
 */

import QtQuick
import Quickshell
import "."
import "../utils/scripts/shellParse.js" as ShellParse

Singleton {
    id: root

    readonly property int storeVersion: WindowStore.version

    property var current: desktopInfo()
    property var previous: desktopInfo()
    property int focusSerial: 0
    property int detailSerial: 0

    readonly property bool hasWindow: current.hasWindow
    readonly property string idString: current.id
    readonly property int numericId: current.numericId
    readonly property string appId: current.appId
    readonly property string className: current.className
    readonly property string title: current.title
    readonly property string rawTitle: current.rawTitle
    readonly property var window: current.window

    property var pending: null

    onStoreVersionChanged: scheduleFromSources()

    Connections {
        target: Hypr

        function onFocusedWindowChanged(): void {
            if (!WMDetector.isNiri)
                root.scheduleFromSources();
        }
    }

    Timer {
        id: commitTimer
        interval: 16
        repeat: false
        onTriggered: root.commitPending()
    }

    Timer {
        id: clearTimer
        interval: 90
        repeat: false
        onTriggered: {
            root.pending = root.desktopInfo();
            commitTimer.restart();
        }
    }

    Component.onCompleted: scheduleFromSources()

    function scheduleFromSources(): void {
        const next = buildCurrentInfo();
        if (next.hasWindow) {
            clearTimer.stop();
            pending = next;
            commitTimer.restart();
            return;
        }

        pending = null;
        clearTimer.restart();
    }

    function commitPending(): void {
        if (!pending)
            return;

        if (sameInfo(current, pending))
            return;

        const focusChanged = !sameFocusIdentity(current, pending);
        if (focusChanged)
            previous = current;
        current = pending;
        if (focusChanged)
            focusSerial++;
        detailSerial++;
    }

    function buildCurrentInfo(): var {
        if (WindowStore.version > 0) {
            const focused = WindowStore.getFocusedWindow();
            if (focused)
                return infoFromStoreWindow(focused);
        }

        if (WMDetector.isNiri)
            return desktopInfo();

        return infoFromHypr();
    }

    function infoFromStoreWindow(win: var): var {
        const cleanApp = cleanWindowText(win.appId || "");
        const cleanTitle = cleanWindowText(win.title || "");
        return {
            hasWindow: true,
            id: normaliseId(win.id),
            numericId: Number(win.id),
            appId: cleanApp,
            className: cleanApp || "Desktop",
            rawTitle: win.title || "",
            title: cleanTitle || "(Unnamed window)",
            detailKey: detailKeyFromStoreWindow(win),
            window: clientFromStoreWindow(win)
        };
    }

    function infoFromHypr(): var {
        const win = Hypr.focusedWindow || null;
        const id = normaliseId(win?.address ? `0x${win.address}` : "");
        if (!id)
            return desktopInfo();

        const cleanApp = cleanWindowText(win?.class || "");
        const cleanTitle = cleanWindowText(win?.title || "");
        return {
            hasWindow: true,
            id: id,
            numericId: Number.NaN,
            appId: cleanApp,
            className: cleanApp || "Desktop",
            rawTitle: win?.title || "",
            title: cleanTitle || "(Unnamed window)",
            detailKey: detailKeyFromClient(win),
            window: win
        };
    }

    function desktopInfo(): var {
        return {
            hasWindow: false,
            id: "",
            numericId: -1,
            appId: "",
            className: "Desktop",
            rawTitle: "",
            title: "Desktop",
            detailKey: "",
            window: null
        };
    }

    function sameInfo(a: var, b: var): bool {
        return ShellParse.sameWindowInfo(a, b);
    }

    function sameFocusIdentity(a: var, b: var): bool {
        return ShellParse.sameFocusIdentity(a, b);
    }

    function clientFromStoreWindow(win: var): var {
        return ShellParse.clientFromStoreWindow(win);
    }

    function detailKeyFromStoreWindow(win: var): string {
        return ShellParse.detailKeyFromStoreWindow(win);
    }

    function detailKeyFromClient(win: var): string {
        return ShellParse.detailKeyFromClient(win);
    }

    function normaliseId(value: var): string {
        if (value === undefined || value === null)
            return "";
        return String(value);
    }

    function cleanWindowText(value: string): string {
        return ShellParse.cleanWindowText(value);
    }
}
