pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import "../../config"
import qs.utils
import Quickshell
import QtQuick

Column {
    id: root

    required property PersistentProperties visibilities

    padding: Config.appearance.padding.large

    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left

    spacing: Config.appearance.spacing.large

    SessionButton {
        id: logout

        icon: "logout"
        command: Config.session.commands.logout

        KeyNavigation.down: shutdown

        Connections {
            target: root.visibilities

            function onSessionChanged(): void {
                if (root.visibilities.session)
                    logout.focus = true;
            }

            function onLauncherChanged(): void {
                if (root.visibilities.session && !root.visibilities.launcher)
                    logout.focus = true;
            }
        }
    }

    SessionButton {
        id: shutdown

        icon: "power_settings_new"
        command: Config.session.commands.shutdown

        KeyNavigation.up: logout
        KeyNavigation.down: hibernate
    }

    // Session decoration - SitkaTree or custom GIF
    Item {
        id: sessionDecoration
        
        width: Config.session.sizes.button
        height: Config.session.sizes.button
        
        // Show SitkaTree if no custom session gif is set, or if it's a sitka image
        property bool useSitkaTree: {
            const path = Config.paths.sessionGif || ""
            return path === "" || path.indexOf("sitka") >= 0
        }
        
        // Procedural ASCII Sitka Spruce Tree
        Loader {
            id: sitkaTreeLoader
            anchors.fill: parent
            active: sessionDecoration.useSitkaTree
            
            sourceComponent: SitkaTree {
                anchors.centerIn: parent
                animated: true
                fontSize: 14
                treeHeight: Math.max(8, Math.floor(parent.height / 18))
                treeWidth: Math.max(7, Math.floor(parent.width / 14))
                
                // Click to regenerate
                MouseArea {
                    anchors.fill: parent
                    onClicked: parent.regenerate()
                }
            }
        }
        
        // Fallback to configured GIF
        Image {
            id: customGif
            anchors.fill: parent
            visible: !sessionDecoration.useSitkaTree
            
            sourceSize.width: width
            sourceSize.height: height
            asynchronous: true
            source: sessionDecoration.useSitkaTree ? "" : Paths.absolutePath(Config.paths.sessionGif)
        }
    }

    SessionButton {
        id: hibernate

        icon: "downloading"
        command: Config.session.commands.hibernate

        KeyNavigation.up: shutdown
        KeyNavigation.down: reboot
    }

    SessionButton {
        id: reboot

        icon: "cached"
        command: Config.session.commands.reboot

        KeyNavigation.up: hibernate
    }

    component SessionButton: StyledRect {
        id: button

        required property string icon
        required property list<string> command

        implicitWidth: Config.session.sizes.button
        implicitHeight: Config.session.sizes.button

        radius: Config.appearance.rounding.large
        color: button.activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer

        Keys.onEnterPressed: Quickshell.execDetached(button.command)
        Keys.onReturnPressed: Quickshell.execDetached(button.command)
        Keys.onEscapePressed: root.visibilities.session = false
        Keys.onPressed: event => {
            if (!Config.session.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J && KeyNavigation.down) {
                    KeyNavigation.down.focus = true;
                    event.accepted = true;
                } else if (event.key === Qt.Key_K && KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                KeyNavigation.down.focus = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                if (KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            }
        }

        StateLayer {
            radius: parent.radius
            color: button.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

            function onClicked(): void {
                Quickshell.execDetached(button.command);
            }
        }

        MaterialIcon {
            anchors.centerIn: parent

            text: button.icon
            color: button.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            font.pointSize: Config.appearance.font.size.extraLarge
            font.weight: 500
        }
    }
}
