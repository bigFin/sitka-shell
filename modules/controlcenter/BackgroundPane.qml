import qs.components
import qs.components.containers
import qs.services
import "../../config"
import qs.utils
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Sitka
import QtQuick

Item {
    id: root

    property FileSystemModel defaultWallpapersModel: FileSystemModel {
        path: Paths.config + "/Images"
        filter: FileSystemModel.Images
        recursive: true
    }

    StyledFlickable {
        anchors.fill: parent
        contentHeight: contentCol.height
        clip: true

        Column {
            id: contentCol
            width: parent.width
            spacing: Config.appearance.spacing.normal
            padding: Config.appearance.padding.large

            StyledText {
                text: qsTr("Options")
                font.bold: true
                color: Colours.palette.m3onSurface
                font.pointSize: Config.appearance.font.size.large
            }

            StyledRect {
                width: parent.width
                height: 50
                radius: Config.appearance.rounding.normal
                color: Colours.palette.m3surfaceContainerHigh

                Row {
                    anchors.centerIn: parent
                    spacing: Config.appearance.spacing.normal
                    
                    MaterialIcon {
                        text: "delete"
                        color: Colours.palette.m3error
                        font.pointSize: Config.appearance.font.size.large
                    }
                    
                    StyledText {
                        text: qsTr("Use System Background")
                        font.bold: true
                        color: Colours.palette.m3onSurface
                    }
                }

                StateLayer {
                    radius: parent.radius
                    onClicked: Wallpapers.setWallpaper("")
                }
            }

            StyledText {
                text: qsTr("Default Wallpapers")
                font.bold: true
                color: Colours.palette.m3onSurface
                font.pointSize: Config.appearance.font.size.large
                topPadding: Config.appearance.padding.large
            }

            Repeater {
                model: root.defaultWallpapersModel.entries

                delegate: Item {
                    width: parent.width
                    height: 150
                    
                    // Add spacing between items
                    anchors.horizontalCenter: parent.horizontalCenter

                    StyledRect {
                        anchors.fill: parent
                        anchors.margins: 2 // small margin
                        color: "transparent"
                        radius: Config.appearance.rounding.normal
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: modelData.filePath
                            fillMode: Image.PreserveAspectCrop
                        }

                        StateLayer {
                            radius: parent.radius
                            onClicked: {
                                Wallpapers.setWallpaper(modelData.filePath);
                            }
                        }
                    }
                }
            }

            StyledText {
                text: qsTr("User Wallpapers")
                font.bold: true
                color: Colours.palette.m3onSurface
                font.pointSize: Config.appearance.font.size.large
                topPadding: Config.appearance.padding.large
            }

            Repeater {
                model: Wallpapers.list

                delegate: Item {
                    width: parent.width
                    height: 150

                    StyledRect {
                        anchors.fill: parent
                        anchors.margins: 2
                        color: "transparent"
                        radius: Config.appearance.rounding.normal
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: modelData.path
                            fillMode: Image.PreserveAspectCrop
                        }

                        StateLayer {
                            radius: parent.radius
                            onClicked: {
                                Wallpapers.setWallpaper(modelData.path);
                            }
                        }
                    }
                }
            }
        }
    }
}
