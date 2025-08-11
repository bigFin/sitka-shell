pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string osName
    property string osPrettyName
    property string osId
    property list<string> osIdLike
    property string logo
    property string osIcon: ""

    readonly property string user: Quickshell.env("USER")
    readonly property string wm: Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP")
    readonly property string shell: Quickshell.env("SHELL").split("/").pop()

    FileView {
        id: osRelease

        path: "/etc/os-release"
        onLoaded: {
            const lines = text().split("\n");

            const fd = key => lines.find(l => l.startsWith(`${key}=`))?.split("=")[1].replace(/"/g, "") ?? "";

            root.osName = fd("NAME");
            root.osPrettyName = fd("PRETTY_NAME");
            root.osId = fd("ID");
            root.osIdLike = fd("ID_LIKE").split(" ");
            root.logo = fd("LOGO");

            const osIcons = Icons.osIcons;
            if (osIcons.hasOwnProperty(root.osId)) {
                root.osIcon = osIcons[root.osId];
            } else {
                for (const id of root.osIdLike) {
                    if (osIcons.hasOwnProperty(id)) {
                        root.osIcon = osIcons[id];
                    }
                }
            }
        }
    }
}
