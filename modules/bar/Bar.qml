pragma ComponentBehavior: Bound

import qs.services
import qs.config
import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts
    readonly property int vPadding: Appearance.padding.large

    // Handle Workspace Popouts for Niri

    Connections {
        target: root.popouts
        function onHasCurrentChanged() {
            if (!root.popouts.hasCurrent && root.popouts.currentName === "wsWindow") {
                Niri.wsAnchorItem = null;
            }
        }
    }

    // Handle Popouts Hover

    function checkPopout(y: real): void {
        const ch = childAt(width / 2, y) as WrappedLoader;
        if (!ch) {
            popouts.hasCurrent = false;
            return;
        }

        const id = ch.id;
        const top = ch.y;
        const item = ch.item;
        const itemHeight = item.implicitHeight;

        if (id === "statusIcons") {
            const items = item.items;
            const icon = items.childAt(items.width / 2, mapToItem(items, 0, y).y);
            if (icon) {
                popouts.currentName = icon.name;
                popouts.currentCenter = Qt.binding(() => icon.mapToItem(root, 0, icon.implicitHeight / 2).y);
                popouts.hasCurrent = true;
            }
        } else if (id === "tray") {
            const index = Math.floor(((y - top) / itemHeight) * item.items.count);
            const trayItem = item.items.itemAt(index);
            if (trayItem) {
                popouts.currentName = `traymenu${index}`;
                popouts.currentCenter = Qt.binding(() => trayItem.mapToItem(root, 0, trayItem.implicitHeight / 2).y);
                popouts.hasCurrent = true;
            }
        } else if (id === "activeWindow") {
            popouts.currentName = id.toLowerCase();
            popouts.currentCenter = item.mapToItem(root, 0, itemHeight / 2).y;
            popouts.hasCurrent = true;
        }
    }

    function handleWheel(y: real, angleDelta: point): void {
        const ch = childAt(width / 2, y) as WrappedLoader;
        if (ch?.id === "workspaces") {
            // Workspace scroll (No special workspaces for niri yet.)

            Niri.switchToWorkspaceUpDown(angleDelta.y > 0 ? "up" : "down");

            // const activeWs = Hyprland.activeToplevel?.workspace?.name;
            // if (activeWs?.startsWith("special:"))
            // Hyprland.dispatch(`togglespecialworkspace ${activeWs.slice(8)}`);
            // else if (angleDelta.y < 0 || Hyprland.activeWsId > 1)
            // Hyprland.dispatch(`workspace r${angleDelta.y > 0 ? "-" : "+"}1`);
        } else if (y < screen.height / 2) {
            // Volume scroll on top half
            if (angleDelta.y > 0)
                Audio.incrementVolume();
            else if (angleDelta.y < 0)
                Audio.decrementVolume();
        } else {
            // Brightness scroll on bottom half
            const monitor = Brightness.getMonitorForScreen(screen);
            if (angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + 0.1);
            else if (angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - 0.1);
        }
    }

    spacing: Appearance.spacing.normal

    Repeater {
        id: repeater

        model: Config.bar.entries

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "spacer"
                delegate: WrappedLoader {
                    Layout.fillHeight: enabled
                }
            }
            DelegateChoice {
                roleValue: "logo"
                delegate: WrappedLoader {
                    sourceComponent: OsIcon {}
                }
            }
            DelegateChoice {
                roleValue: "workspaces"
                delegate: WrappedLoader {
                    sourceComponent: Workspaces {

                        property var anchorItem: Niri.wsAnchorItem ? Niri.wsAnchorItem : null

                        onRequestWindowPopout: {
                            if (anchorItem) {
                                root.popouts.currentName = "wsWindow";
                                root.popouts.currentCenter = Qt.binding(() => Math.round(anchorItem.mapToItem(null, anchorItem.width, (anchorItem.height) / 2).y));
                                root.popouts.hasCurrent = true;
                            }
                        }
                    }
                }
            }
            DelegateChoice {
                roleValue: "activeWindow"
                delegate: WrappedLoader {
                    sourceComponent: ActiveWindow {
                        bar: root
                        monitor: Brightness.getMonitorForScreen(root.screen)
                    }
                }
            }
            DelegateChoice {
                roleValue: "tray"
                delegate: WrappedLoader {
                    sourceComponent: Tray {}
                }
            }
            DelegateChoice {
                roleValue: "clock"
                delegate: WrappedLoader {
                    sourceComponent: Clock {}
                }
            }
            DelegateChoice {
                roleValue: "statusIcons"
                delegate: WrappedLoader {
                    sourceComponent: StatusIcons {}
                }
            }
            DelegateChoice {
                roleValue: "power"
                delegate: WrappedLoader {
                    sourceComponent: Power {
                        visibilities: root.visibilities
                    }
                }
            }
        }
    }

    component WrappedLoader: Loader {
        required property bool enabled
        required property string id
        required property int index

        function findFirstEnabled(): Item {
            const count = repeater.count;
            for (let i = 0; i < count; i++) {
                const item = repeater.itemAt(i);
                if (item?.enabled)
                    return item;
            }
            return null;
        }

        function findLastEnabled(): Item {
            for (let i = repeater.count - 1; i >= 0; i--) {
                const item = repeater.itemAt(i);
                if (item?.enabled)
                    return item;
            }
            return null;
        }

        Layout.alignment: Qt.AlignHCenter

        // Cursed ahh thing to add padding to first and last enabled components
        Layout.topMargin: findFirstEnabled() === this ? root.vPadding : 0
        Layout.bottomMargin: findLastEnabled() === this ? root.vPadding : 0

        visible: enabled
        active: enabled
        asynchronous: true
    }
}
