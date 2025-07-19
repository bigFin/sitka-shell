pragma Singleton

import qs.utils
import Quickshell

Searcher {
    id: root

    list: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))

    function launch(entry: DesktopEntry): void {
        if (entry.runInTerminal)
            Quickshell.execDetached(["app2unit", "--", "foot", "fish", "-C", entry.execString]);
        else if (entry.execString.startsWith("sh -c"))
            Quickshell.execDetached(["sh", "-c", `app2unit -- ${entry.execString}`]);
        else
            Quickshell.execDetached(["sh", "-c", `app2unit -- '${entry.id}.desktop' || app2unit -- ${entry.execString}`]);
    }
}
