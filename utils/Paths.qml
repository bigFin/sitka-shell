pragma Singleton

import qs.config
import Sitka
import Quickshell

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string pictures: Quickshell.env("XDG_PICTURES_DIR") || `${home}/Pictures`

    readonly property string data: `${Quickshell.env("XDG_DATA_HOME") || `${home}/.local/share`}/sitka`
    readonly property string state: `${Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`}/sitka`
    readonly property string cache: `${Quickshell.env("XDG_CACHE_HOME") || `${home}/.cache`}/sitka`
    readonly property string config: Quickshell.env("SITKA_CONFIG_DIR") || `${Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`}/sitka`

    readonly property string imagecache: `${cache}/imagecache`
    readonly property string wallsdir: Quickshell.env("SITKA_WALLPAPERS_DIR") || absolutePath(Config.paths.wallpaperDir)
    readonly property string libdir: Quickshell.env("SITKA_LIB_DIR") || "/usr/lib/sitka"

    function toLocalFile(path: url): string {
        path = Qt.resolvedUrl(path);
        return path.toString() ? CUtils.toLocalFile(path) : "";
    }

    function absolutePath(path: string): string {
        return toLocalFile(path.replace("~", home));
    }

    function shortenHome(path: string): string {
        return path.replace(home, "~");
    }
}
