pragma Singleton

import Quickshell

Singleton {
    property var screens: new Map()

    function load(screen: ShellScreen, visibilities: var): void {
        screens.set(screen.model + screen.name, visibilities);
    }

    function getForActive(): PersistentProperties {
        const mon = Hyprland.focusedMonitor;
        return screens.get(mon.lastIpcObject.model + mon.name);
    }
}
