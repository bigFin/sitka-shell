pragma Singleton

import Quickshell
import Quickshell.Hyprland

Singleton {
    property var screens: new Map()

    function load(screen: ShellScreen, visibilities: var): void {
        screens.set(Hyprland.monitorFor(screen), visibilities);
    }

    function getForActive(): PersistentProperties {
        return Object.entries(screens).find(s => s[0].slice(s[0].indexOf('"') + 1, s[0].lastIndexOf('"')) === Niri.focusedMonitorName)[1];
    }
}
