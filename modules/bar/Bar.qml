pragma ComponentBehavior: Bound

import qs.services
import "../../config"
import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import qs.modules.controlcenter
import qs.components
import qs.components.controls
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts

    height: screen.height
    readonly property int vPadding: Config.appearance.padding.small

    // Handle Workspace Popouts for Niri



    Connections {
        target: root.popouts
        function onHasCurrentChanged() {
            if (!root.popouts.hasCurrent && root.popouts.currentName === "wsWindow") {
                WMService.wsContextAnchor = null;
            }
        }
    }

    // Handle Popouts Hover

    function checkPopout(y: real): void {
        if (WMService.wsContextType === "workspaces") {
            // Workspace context menu
            const anchor = WMService.wsContextAnchor;
            if (!anchor) {
                popouts.hasCurrent = false;
                return;
            }
            popouts.currentCenter = Qt.binding(() => Math.round(anchor.mapToItem(root, anchor.width, (anchor.height) / 2).y));
            return;
        }

        const adjustedY = y + flickable.contentY;
        const ch = entriesLayout.childAt(width / 2, adjustedY) as WrappedLoader;
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
            const icon = items.childAt(items.width / 2, mapToItem(items, 0, adjustedY).y);
            if (icon) {
                popouts.currentName = icon.name;
                popouts.currentCenter = Qt.binding(() => icon.mapToItem(root, 0, icon.implicitHeight / 2).y);
                popouts.hasCurrent = true;
            }
        } else if (id === "tray") {
            const index = Math.floor(((adjustedY - top) / itemHeight) * item.items.count);
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
        const adjustedY = y + flickable.contentY;
        const ch = entriesLayout.childAt(width / 2, adjustedY) as WrappedLoader;
        if (ch?.id === "workspaces" && Config.bar.scrollActions.workspaces) {
            // Workspace scroll (No special workspaces for niri yet.)

            WMService.switchToWorkspaceUpDown(angleDelta.y > 0 ? "up" : "down");

            // const activeWs = Hyprland.activeToplevel?.workspace?.name;
            // if (activeWs?.startsWith("special:"))
            // Hyprland.dispatch(`togglespecialworkspace ${activeWs.slice(8)}`);
            // else if (angleDelta.y < 0 || Hyprland.activeWsId > 1)
            // Hyprland.dispatch(`workspace r${angleDelta.y > 0 ? "-" : "+"}1`);
        } else if (adjustedY < screen.height / 2 && Config.bar.scrollActions.workspaces) {
            // Volume scroll on top half
            if (angleDelta.y > 0)
                Audio.incrementVolume();
            else if (angleDelta.y < 0)
                Audio.decrementVolume();
        } else if (Config.bar.scrollActions.brightness) {
            // Brightness scroll on bottom half
            const monitor = Brightness.getMonitorForScreen(screen);
            if (angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + 0.1);
            else if (angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - 0.1);
        }
    }

    Flickable {
        id: flickable

        anchors.fill: parent

        contentHeight: entriesLayout.implicitHeight
        interactive: contentHeight > height
        clip: true

        ColumnLayout {
            id: entriesLayout
            width: flickable.width
            height: Math.max(implicitHeight, flickable.height)
            spacing: Config.appearance.spacing.normal

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
                            sourceComponent: OsIcon {
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.LeftButton) {
                                            root.visibilities.launcher = true;
                                        } else if (mouse.button === Qt.RightButton) {
                                            WMService.wsContextType = "workspaces";
                                            root.popouts.currentName = "wsWindow";
                                            root.popouts.hasCurrent = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    DelegateChoice {
                        roleValue: "workspaces"
                        delegate: WrappedLoader {
                            sourceComponent: Workspaces {
                                screen: root.screen
                                property var anchorItem: WMService.wsContextAnchor && WMService.wsContextType !== "none" ? WMService.wsContextAnchor : null

                                onRequestWindowPopout: {
                                    if (anchorItem && Config.bar.workspaces.windowRighClickContext) {
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
                        roleValue: "pin"
                        delegate: WrappedLoader {
                            sourceComponent: Pin {
                                visibilities: root.visibilities
                            }
                        }
                    }
                    DelegateChoice {
                        roleValue: "logoToggle"
                        delegate: WrappedLoader {
                            sourceComponent: LogoToggle {
                                visibilities: root.visibilities
                            }
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
                    DelegateChoice {
                        roleValue: "papertoy"
                        delegate: WrappedLoader {
                            sourceComponent: Papertoy {}
                        }
                    }
                    DelegateChoice {
                        roleValue: "idleInhibitor"
                        delegate: WrappedLoader {
                            sourceComponent: IdleInhibitor {}
                        }
                    }
                    DelegateChoice {
                        roleValue: "screenRecorder"
                        delegate: WrappedLoader {
                            sourceComponent: ScreenRecorder {}
                        }
                    }
                    DelegateChoice {
                        roleValue: "utilities"
                        delegate: WrappedLoader {
                            sourceComponent: UtilitiesToggle {
                                visibilities: root.visibilities
                            }
                        }
                    }
                    DelegateChoice {
                        roleValue: "controlcenter"
                        delegate: WrappedLoader {
                            sourceComponent: BarIcon {
                                icon: "settings"
                                onClicked: WindowFactory.create()
                            }
                        }
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
        active: true
    }

    component BarIcon: StyledRect {
        id: barIconRoot

        required property string icon
        signal clicked()

        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Config.appearance.padding.small * 2
        radius: Config.appearance.rounding.full

        MaterialIcon {
            id: icon
            anchors.centerIn: parent
            text: barIconRoot.icon
            color: Colours.palette.m3onSurface
            font.pointSize: Config.appearance.font.size.normal
        }

        StateLayer {
            radius: parent.radius
            onClicked: barIconRoot.clicked()
        }
    }
}
