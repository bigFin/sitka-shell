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
        return a.hasWindow === b.hasWindow
            && a.id === b.id
            && a.appId === b.appId
            && a.title === b.title
            && a.rawTitle === b.rawTitle
            && a.detailKey === b.detailKey;
    }

    function sameFocusIdentity(a: var, b: var): bool {
        return a.hasWindow === b.hasWindow && a.id === b.id;
    }

    function clientFromStoreWindow(win: var): var {
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

    function detailKeyFromStoreWindow(win: var): string {
        return [
            win.id,
            win.workspaceId,
            win.pid,
            win.appId,
            win.title,
            win.isFloating,
            win.isUrgent,
            win.layoutCol,
            win.layoutRow,
            win.tilePosX,
            win.tilePosY,
            win.width,
            win.height
        ].join("|");
    }

    function detailKeyFromClient(win: var): string {
        if (!win)
            return "";
        const layout = win.layout || {};
        const pos = layout.pos_in_scrolling_layout || [];
        const tilePos = layout.tile_pos_in_workspace_view || [];
        const size = layout.window_size || [];
        return [
            win.id ?? "",
            win.workspace_id ?? "",
            win.pid ?? "",
            win.app_id ?? win.class ?? "",
            win.title ?? "",
            win.is_floating ?? win.floating ?? false,
            win.is_urgent ?? false,
            pos[0] ?? "",
            pos[1] ?? "",
            tilePos[0] ?? "",
            tilePos[1] ?? "",
            size[0] ?? "",
            size[1] ?? ""
        ].join("|");
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
