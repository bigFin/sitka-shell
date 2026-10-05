import qs.components.misc
import qs.modules.controlcenter
import qs.services
import Quickshell
import Quickshell.Io

Scope {
    id: root

    IpcHandler {
        target: "drawers"

        function toggle(drawer: string): void {
            if (list().split("\n").includes(drawer)) {
                const visibilities = Visibilities.getForActive();
                if (!visibilities)
                    return;
                if (["launcher", "session", "dashboard"].includes(drawer))
                    visibilities.setDrawer(drawer, !(visibilities[drawer] && visibilities.keyboardOwner === drawer), "explicit");
                else
                    visibilities[drawer] = !visibilities[drawer];
            } else {
                console.warn(`[IPC] Drawer "${drawer}" does not exist`);
            }
        }

        function list(): string {
            const visibilities = Visibilities.getForActive();
            return visibilities ? Object.keys(visibilities).filter(k => k !== "changingDrawer" && typeof visibilities[k] === "boolean").join("\n") : "";
        }
    }

    IpcHandler {
        target: "controlCenter"

        function open(): void {
            WindowFactory.create();
        }
    }
}
