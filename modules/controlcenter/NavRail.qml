pragma ComponentBehavior: Bound

import qs.components
import qs.services
import "../../config"
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    required property Session session

    implicitWidth: layout.implicitWidth + Config.appearance.padding.larger * 4
    implicitHeight: layout.implicitHeight + Config.appearance.padding.large * 2

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Config.appearance.padding.larger * 2
        spacing: Config.appearance.spacing.normal

        states: State {
            name: "expanded"
            when: root.session.navExpanded

            PropertyChanges {
                layout.spacing: Config.appearance.spacing.small
                menuIcon.opacity: 0
                menuIconExpanded.opacity: 1
                menuIcon.rotation: 180
                menuIconExpanded.rotation: 0
            }
        }

        transitions: Transition {
            Anim {
                properties: "spacing,opacity,rotation"
            }
        }

        Item {
            id: menuBtn

            Layout.topMargin: Config.appearance.spacing.large
            implicitWidth: menuIcon.implicitWidth + menuIcon.anchors.leftMargin * 2
            implicitHeight: menuIcon.implicitHeight + Config.appearance.padding.normal * 2

            StateLayer {
                radius: Config.appearance.rounding.small

                function onClicked(): void {
                    root.session.navExpanded = !root.session.navExpanded;
                }
            }

            MaterialIcon {
                id: menuIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Config.appearance.padding.large

                text: "menu"
                font.pointSize: Config.appearance.font.size.large
            }

            MaterialIcon {
                id: menuIconExpanded

                anchors.fill: menuIcon
                text: "menu_open"
                font.pointSize: menuIcon.font.pointSize
                opacity: 0
                rotation: -180
            }
        }

        Loader {
            asynchronous: true
            active: !root.session.floating
            visible: active

            sourceComponent: StyledRect {
                readonly property int nonAnimWidth: normalWinIcon.implicitWidth + (root.session.navExpanded ? normalWinLabel.anchors.leftMargin + normalWinLabel.implicitWidth : 0) + normalWinIcon.anchors.leftMargin * 2

                implicitWidth: nonAnimWidth
                implicitHeight: root.session.navExpanded ? normalWinIcon.implicitHeight + Config.appearance.padding.normal * 2 : nonAnimWidth

                color: Colours.palette.m3primaryContainer
                radius: Config.appearance.rounding.small

                StateLayer {
                    id: normalWinState

                    color: Colours.palette.m3onPrimaryContainer

                    function onClicked(): void {
                        root.session.root.close();
                        WindowFactory.create(null, {
                            screen: root.screen,
                            active: root.session.active,
                            navExpanded: root.session.navExpanded
                        });
                    }
                }

                MaterialIcon {
                    id: normalWinIcon

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Config.appearance.padding.large

                    text: "select_window"
                    color: Colours.palette.m3onPrimaryContainer
                    font.pointSize: Config.appearance.font.size.large
                    fill: 1
                }

                StyledText {
                    id: normalWinLabel

                    anchors.left: normalWinIcon.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Config.appearance.spacing.normal

                    text: qsTr("Float window")
                    color: Colours.palette.m3onPrimaryContainer
                    opacity: root.session.navExpanded ? 1 : 0

                    Behavior on opacity {
                        Anim {
                            duration: Config.appearance.anim.durations.small
                        }
                    }
                }

                Behavior on implicitWidth {
                    Anim {
                        duration: Config.appearance.anim.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
                    }
                }

                Behavior on implicitHeight {
                    Anim {
                        duration: Config.appearance.anim.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
                    }
                }
            }
        }

        NavItem {
            Layout.topMargin: Config.appearance.spacing.large * 2
            icon: "network_manage"
            label: "network"
        }

        NavItem {
            icon: "settings_bluetooth"
            label: "bluetooth"
        }

        NavItem {
            icon: "tune"
            label: "audio"
        }
    }

    component NavItem: Item {
        id: item

        required property string icon
        required property string label
        readonly property bool active: root.session.active === label

        implicitWidth: background.implicitWidth
        implicitHeight: background.implicitHeight + smallLabel.implicitHeight + smallLabel.anchors.topMargin

        states: State {
            name: "expanded"
            when: root.session.navExpanded

            PropertyChanges {
                expandedLabel.opacity: 1
                smallLabel.opacity: 0
                background.implicitWidth: icon.implicitWidth + icon.anchors.leftMargin * 2 + expandedLabel.anchors.leftMargin + expandedLabel.implicitWidth
                background.implicitHeight: icon.implicitHeight + Config.appearance.padding.normal * 2
                item.implicitHeight: background.implicitHeight
            }
        }

        transitions: Transition {
            Anim {
                property: "opacity"
                duration: Config.appearance.anim.durations.small
            }

            Anim {
                properties: "implicitWidth,implicitHeight"
                duration: Config.appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
            }
        }

        StyledRect {
            id: background

            radius: Config.appearance.rounding.full
            color: item.active ? Colours.palette.m3secondaryContainer : "transparent"

            implicitWidth: icon.implicitWidth + icon.anchors.leftMargin * 2
            implicitHeight: icon.implicitHeight + Config.appearance.padding.small

            StateLayer {
                color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

                function onClicked(): void {
                    root.session.active = item.label;
                }
            }

            MaterialIcon {
                id: icon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Config.appearance.padding.large

                text: item.icon
                color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font.pointSize: Config.appearance.font.size.large
                fill: item.active ? 1 : 0

                Behavior on fill {
                    Anim {}
                }
            }

            StyledText {
                id: expandedLabel

                anchors.left: icon.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Config.appearance.spacing.normal

                opacity: 0
                text: item.label
                color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font.capitalization: Font.Capitalize
            }

            StyledText {
                id: smallLabel

                anchors.horizontalCenter: icon.horizontalCenter
                anchors.top: icon.bottom
                anchors.topMargin: Config.appearance.spacing.small / 2

                text: item.label
                font.pointSize: Config.appearance.font.size.small
                font.capitalization: Font.Capitalize
            }
        }
    }
}
