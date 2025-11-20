pragma ComponentBehavior: Bound

import ".."
import qs.services
import "../../config"
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property var dialog

    implicitWidth: Sizes.sidebarWidth
    implicitHeight: inner.implicitHeight + Config.appearance.padding.normal * 2

    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: inner

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Config.appearance.padding.normal
        spacing: Config.appearance.spacing.small / 2

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Config.appearance.padding.small / 2
            Layout.bottomMargin: Config.appearance.spacing.normal
            text: qsTr("Files")
            color: Colours.palette.m3onSurface
            font.pointSize: Config.appearance.font.size.larger
            font.bold: true
        }

        Repeater {
            model: ["Home", "Downloads", "Desktop", "Documents", "Music", "Pictures", "Videos"]

            StyledRect {
                id: place

                required property string modelData
                readonly property bool selected: modelData === root.dialog.cwd[root.dialog.cwd.length - 1]

                Layout.fillWidth: true
                implicitHeight: placeInner.implicitHeight + Config.appearance.padding.normal * 2

                radius: Config.appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3secondaryContainer, selected ? 1 : 0)

                StateLayer {
                    color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

                    function onClicked(): void {
                        if (place.modelData === "Home")
                            root.dialog.cwd = ["Home"];
                        else
                            root.dialog.cwd = ["Home", place.modelData];
                    }
                }

                RowLayout {
                    id: placeInner

                    anchors.fill: parent
                    anchors.margins: Config.appearance.padding.normal
                    anchors.leftMargin: Config.appearance.padding.large
                    anchors.rightMargin: Config.appearance.padding.large

                    spacing: Config.appearance.spacing.normal

                    MaterialIcon {
                        text: {
                            const p = place.modelData;
                            if (p === "Home")
                                return "home";
                            if (p === "Downloads")
                                return "file_download";
                            if (p === "Desktop")
                                return "desktop_windows";
                            if (p === "Documents")
                                return "description";
                            if (p === "Music")
                                return "music_note";
                            if (p === "Pictures")
                                return "image";
                            if (p === "Videos")
                                return "video_library";
                            return "folder";
                        }
                        color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        font.pointSize: Config.appearance.font.size.large
                        fill: place.selected ? 1 : 0

                        Behavior on fill {
                            Anim {}
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: place.modelData
                        color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        font.pointSize: Config.appearance.font.size.normal
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
