pragma ComponentBehavior: Bound

import ".."
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property list<string> cwd

    spacing: Appearance.spacing.small

    Item {
        implicitWidth: implicitHeight
        implicitHeight: upIcon.implicitHeight + Appearance.padding.small * 2

        StateLayer {
            radius: Appearance.rounding.small

            function onClicked(): void {
                root.cwd.pop();
            }
        }

        MaterialIcon {
            id: upIcon

            anchors.centerIn: parent
            text: "drive_folder_upload"
        }
    }

    StyledRect {
        Layout.fillWidth: true

        radius: Appearance.rounding.small
        color: Colours.palette.m3surfaceContainer

        implicitHeight: pathComponents.implicitHeight + pathComponents.anchors.margins * 2

        RowLayout {
            id: pathComponents

            anchors.fill: parent
            anchors.margins: Appearance.padding.small
            anchors.leftMargin: 0

            spacing: Appearance.spacing.small

            Repeater {
                model: root.cwd

                RowLayout {
                    id: folder

                    required property string modelData
                    required property int index

                    spacing: 0

                    Loader {
                        Layout.rightMargin: Appearance.spacing.small
                        active: folder.index > 0
                        asynchronous: true
                        sourceComponent: StyledText {
                            text: "/"
                            color: Colours.palette.m3onSurfaceVariant
                            font.bold: true
                        }
                    }

                    Item {
                        implicitWidth: homeIcon.implicitWidth + (homeIcon.active ? Appearance.padding.small : 0) + folderName.implicitWidth + Appearance.padding.normal * 2
                        implicitHeight: Math.max(homeIcon.implicitHeight, folderName.implicitHeight) + Appearance.padding.small * 2

                        Loader {
                            anchors.fill: parent
                            active: folder.index < root.cwd.length - 1
                            asynchronous: true
                            sourceComponent: StateLayer {
                                radius: Appearance.rounding.small

                                function onClicked(): void {
                                    root.cwd = root.cwd.slice(0, folder.index);
                                }
                            }
                        }

                        Loader {
                            id: homeIcon

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Appearance.padding.normal

                            active: folder.index === 0 && folder.modelData === "Home"
                            asynchronous: true
                            sourceComponent: MaterialIcon {
                                text: "home"
                                color: root.cwd.length === 1 ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                                fill: 1
                            }
                        }

                        StyledText {
                            id: folderName

                            anchors.left: homeIcon.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: homeIcon.active ? Appearance.padding.small : 0

                            text: folder.modelData
                            color: folder.index < root.cwd.length - 1 ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
                            font.bold: true
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }
}
