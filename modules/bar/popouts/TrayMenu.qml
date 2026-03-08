pragma ComponentBehavior: Bound

import qs.components
import qs.services
import "../../../config"
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls

StackView {
    id: root

    required property Item popouts
    required property QsMenuHandle trayItem

    implicitWidth: currentItem.implicitWidth
    implicitHeight: currentItem.implicitHeight

    initialItem: SubMenu {
        handle: root.trayItem
    }

    pushEnter: NoAnim {}
    pushExit: NoAnim {}
    popEnter: NoAnim {}
    popExit: NoAnim {}

    HyprlandFocusGrab {
        active: WMDetector.isHyprland
        windows: [QsWindow.window]
        onCleared: root.popouts.hasCurrent = false
    }

    component NoAnim: Transition {
        NumberAnimation {
            duration: 0
        }
    }

    component SubMenu: Column {
        id: menu

        required property QsMenuHandle handle
        property bool isSubMenu
        property bool shown

        padding: Config.appearance.padding.smaller
        spacing: Config.appearance.spacing.small

        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.8

        Component.onCompleted: shown = true
        StackView.onActivating: shown = true
        StackView.onDeactivating: shown = false
        StackView.onRemoved: destroy()

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {}
        }

        QsMenuOpener {
            id: menuOpener

            menu: menu.handle
        }

        Repeater {
            model: menuOpener.children

            StyledRect {
                id: item

                required property var modelData
                readonly property var entry: modelData

                implicitWidth: Config.bar.sizes.trayMenuWidth
                implicitHeight: entry?.isSeparator ? 1 : children.implicitHeight

                radius: Config.appearance.rounding.full
                color: entry?.isSeparator ? Colours.palette.m3outlineVariant : "transparent"

                Loader {
                    id: children

                    anchors.left: parent.left
                    anchors.right: parent.right

                    active: !(item.entry?.isSeparator ?? true)
                    asynchronous: true

                    sourceComponent: Item {
                        implicitHeight: label.implicitHeight

                        StateLayer {
                            anchors.margins: -Config.appearance.padding.small / 2
                            anchors.leftMargin: -Config.appearance.padding.smaller
                            anchors.rightMargin: -Config.appearance.padding.smaller

                            radius: item.radius
                            disabled: !(item.entry?.enabled ?? false)

                            function onClicked(): void {
                                const entry = item.modelData;
                                if (!entry)
                                    return;
                                if (entry.hasChildren)
                                    root.push(subMenuComp.createObject(null, {
                                        handle: entry,
                                        isSubMenu: true
                                    }));
                                else {
                                    entry.triggered();
                                    root.popouts.hasCurrent = false;
                                }
                            }
                        }

                        Loader {
                            id: icon

                            anchors.left: parent.left

                            active: (item.entry?.icon ?? "") !== ""
                            asynchronous: true

                            sourceComponent: IconImage {
                                implicitSize: label.implicitHeight

                                source: item.entry?.icon ?? ""
                            }
                        }

                        StyledText {
                            id: label

                            anchors.left: icon.right
                            anchors.leftMargin: icon.active ? Config.appearance.spacing.smaller : 0

                            text: labelMetrics.elidedText
                            color: (item.entry?.enabled ?? false) ? Colours.palette.m3onSurface : Colours.palette.m3outline
                        }

                        TextMetrics {
                            id: labelMetrics

                            text: item.entry?.text ?? ""
                            font.pointSize: label.font.pointSize
                            font.family: label.font.family

                            elide: Text.ElideRight
                            elideWidth: Config.bar.sizes.trayMenuWidth - (icon.active ? icon.implicitWidth + label.anchors.leftMargin : 0) - (expand.active ? expand.implicitWidth + Config.appearance.spacing.normal : 0)
                        }

                        Loader {
                            id: expand

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right

                            active: item.entry?.hasChildren ?? false
                            asynchronous: true

                            sourceComponent: MaterialIcon {
                                text: "chevron_right"
                                color: (item.entry?.enabled ?? false) ? Colours.palette.m3onSurface : Colours.palette.m3outline
                            }
                        }
                    }
                }
            }
        }

        Loader {
            active: menu.isSubMenu
            asynchronous: true

            sourceComponent: Item {
                implicitWidth: back.implicitWidth
                implicitHeight: back.implicitHeight + Config.appearance.spacing.small / 2

                Item {
                    anchors.bottom: parent.bottom
                    implicitWidth: back.implicitWidth
                    implicitHeight: back.implicitHeight

                    StyledRect {
                        anchors.fill: parent
                        anchors.margins: -Config.appearance.padding.small / 2
                        anchors.leftMargin: -Config.appearance.padding.smaller
                        anchors.rightMargin: -Config.appearance.padding.smaller * 2

                        radius: Config.appearance.rounding.full
                        color: Colours.palette.m3secondaryContainer

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onSecondaryContainer

                            function onClicked(): void {
                                root.pop();
                            }
                        }
                    }

                    Row {
                        id: back

                        anchors.verticalCenter: parent.verticalCenter

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "chevron_left"
                            color: Colours.palette.m3onSecondaryContainer
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Back")
                            color: Colours.palette.m3onSecondaryContainer
                        }
                    }
                }
            }
        }
    }

    Component {
        id: subMenuComp

        SubMenu {}
    }
}
