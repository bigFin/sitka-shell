pragma Singleton

import qs.services
import Quickshell
import QtQuick
import "../utils/scripts/drawerState.js" as DrawerState
Singleton {
    id: root

    property var screens: new Map()
    property var bars: new Map()
    property var barPinnedByScreen: ({})
    property var barOpenByScreen: ({})

    PersistentProperties {
        id: props

        property string barPinnedJson: "{}"
        property string barOpenJson: "{}"

        reloadableId: "visibilities"
    }

    Component.onCompleted: {
        try {
            const parsed = JSON.parse(props.barPinnedJson || "{}");
            if (parsed && typeof parsed === "object")
                root.barPinnedByScreen = parsed;
        } catch (e) {
            console.warn("Visibilities: Failed to parse persisted bar state:", e);
            root.barPinnedByScreen = ({});
        }

        try {
            const parsedOpen = JSON.parse(props.barOpenJson || "{}");
            if (parsedOpen && typeof parsedOpen === "object")
                root.barOpenByScreen = parsedOpen;
        } catch (e) {
            console.warn("Visibilities: Failed to parse persisted open state:", e);
            root.barOpenByScreen = ({});
        }
    }

    function screenKey(screen: ShellScreen): string {
        return screen?.name ?? "";
    }

    function load(screen: ShellScreen, visibilities: PersistentProperties): void {
        // Name-keyed only: no reader looks screens up by object identity,
        // and object keys would leak across monitor replugs.
        const key = screenKey(screen);
        if (!key)
            return;
        screens.set(key, visibilities);
    }

    function unload(screenName: string, visibilities: PersistentProperties): void {
        DrawerState.unregister(screens, screenName, visibilities);
    }

    function unregisterBar(bar: Item): void {
        // The ShellScreen may already be invalid during destruction. Remove
        // only entries belonging to this bar, including its object-key alias.
        DrawerState.unregisterValue(bars, bar);
    }

    function claimKeyboard(owner: PersistentProperties): void {
        DrawerState.claimKeyboard(screens, owner);
    }

    function getForScreen(screenName: string): PersistentProperties {
        return screens.get(screenName) ?? null;
    }

    function registerBar(screen: ShellScreen, bar: Item): void {
        const key = screenKey(screen);
        if (!key)
            return;
        bars.set(screen, bar);
        bars.set(key, bar);
    }

    function getForActive(): PersistentProperties {
        return DrawerState.activeScreen(screens, WMService.focusedMonitorName);
    }

    function getBarPinned(screenName: string): var {
        if (!screenName)
            return null;
        if (!Object.prototype.hasOwnProperty.call(barPinnedByScreen, screenName))
            return null;
        return !!barPinnedByScreen[screenName];
    }

    function setBarPinned(screenName: string, pinned: bool): void {
        if (!screenName)
            return;
        if (barPinnedByScreen[screenName] === pinned)
            return;

        barPinnedByScreen[screenName] = pinned;
        props.barPinnedJson = JSON.stringify(barPinnedByScreen);
    }

    function getBarOpen(screenName: string): var {
        if (!screenName)
            return null;
        if (!Object.prototype.hasOwnProperty.call(barOpenByScreen, screenName))
            return null;
        return !!barOpenByScreen[screenName];
    }

    function setBarOpen(screenName: string, open: bool): void {
        if (!screenName)
            return;
        if (barOpenByScreen[screenName] === open)
            return;

        barOpenByScreen[screenName] = open;
        props.barOpenJson = JSON.stringify(barOpenByScreen);
    }
}
