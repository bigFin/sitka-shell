pragma Singleton

import qs.services
import Quickshell
import QtQuick

Singleton {
    id: root

    property var screens: new Map()
    property var bars: new Map()
    property var barPinnedByScreen: ({})

    PersistentProperties {
        id: props

        property string barPinnedJson: "{}"

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
    }

    function screenKey(screen: ShellScreen): string {
        return screen?.name ?? "";
    }

    function load(screen: ShellScreen, visibilities: PersistentProperties): void {
        const key = screenKey(screen);
        if (!key)
            return;
        screens.set(screen, visibilities);
        screens.set(key, visibilities);
    }

    function registerBar(screen: ShellScreen, bar: Item): void {
        const key = screenKey(screen);
        if (!key)
            return;
        bars.set(screen, bar);
        bars.set(key, bar);
    }

    function getForActive(): PersistentProperties {
        const active = screens.get(WMService.focusedMonitorName);
        if (active)
            return active;

        const all = Array.from(screens.values());
        return all.length ? all[0] : null;
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
}
