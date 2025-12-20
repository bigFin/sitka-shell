import qs.components
import qs.components.containers
import qs.components.filedialog
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
    anchors.fill: parent

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

            // Use System Background Button
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

            // Browse Button
            StyledRect {
                width: parent.width
                height: 50
                radius: Config.appearance.rounding.normal
                color: Colours.palette.m3surfaceContainerHigh
                
                FileDialog {
                     id: fileDialog
                     title: qsTr("Select a wallpaper")
                     filterLabel: qsTr("Image files")
                     filters: Images.validImageExtensions
                     onAccepted: path => Wallpapers.setWallpaper(path)
                }

                Row {
                    anchors.centerIn: parent
                    spacing: Config.appearance.spacing.normal
                    
                    MaterialIcon {
                        text: "folder_open"
                        color: Colours.palette.m3primary
                        font.pointSize: Config.appearance.font.size.large
                    }
                    
                    StyledText {
                        text: qsTr("Browse Files...")
                        font.bold: true
                        color: Colours.palette.m3onSurface
                    }
                }

                StateLayer {
                    radius: parent.radius
                    onClicked: fileDialog.open()
                }
            }

            // Papertoy Shader Background Section
            StyledText {
                text: qsTr("Shader Background (Papertoy)")
                font.bold: true
                color: Colours.palette.m3onSurface
                font.pointSize: Config.appearance.font.size.large
                topPadding: Config.appearance.padding.large
            }

            // Papertoy Toggle Button
            StyledRect {
                width: parent.width
                height: 50
                radius: Config.appearance.rounding.normal
                color: Papertoy.enabled 
                    ? Colours.palette.m3primaryContainer 
                    : Colours.palette.m3surfaceContainerHigh

                Row {
                    anchors.centerIn: parent
                    spacing: Config.appearance.spacing.normal
                    
                    StyledText {
                        text: Papertoy.enabled ? "󰫕" : "󰫖"
                        animate: true
                        color: Papertoy.enabled 
                            ? Colours.palette.m3onPrimaryContainer 
                            : Colours.palette.m3primary
                        font.pointSize: Config.appearance.font.size.large
                    }
                    
                    StyledText {
                        text: Papertoy.enabled ? qsTr("Shader Active") : qsTr("Enable Shader Background")
                        font.bold: true
                        color: Papertoy.enabled 
                            ? Colours.palette.m3onPrimaryContainer 
                            : Colours.palette.m3onSurface
                    }
                }

                StateLayer {
                    radius: parent.radius
                    onClicked: Papertoy.enabled = !Papertoy.enabled
                }
            }

            // Current Shader Path Display
            StyledRect {
                width: parent.width
                height: shaderPathCol.implicitHeight + Config.appearance.padding.normal * 2
                radius: Config.appearance.rounding.normal
                color: Colours.palette.m3surfaceContainerHigh
                visible: Papertoy.currentShaderPath !== ""

                Column {
                    id: shaderPathCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Config.appearance.padding.normal
                    spacing: Config.appearance.spacing.small

                    StyledText {
                        text: qsTr("Current Shader")
                        font.bold: true
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Config.appearance.font.size.small
                    }

                    StyledText {
                        width: parent.width
                        text: Paths.shortenHome(Papertoy.currentShaderPath)
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideMiddle
                    }
                }
            }

            // Browse Shader Button
            StyledRect {
                width: parent.width
                height: 50
                radius: Config.appearance.rounding.normal
                color: Colours.palette.m3surfaceContainerHigh
                
                FileDialog {
                    id: shaderFileDialog
                    title: qsTr("Select a shader")
                    filterLabel: qsTr("GLSL shader files")
                    filters: ["*.glsl", "*.frag", "*.vert"]
                    onAccepted: path => Papertoy.setShaderPath(path)
                }

                Row {
                    anchors.centerIn: parent
                    spacing: Config.appearance.spacing.normal
                    
                    MaterialIcon {
                        text: "folder_open"
                        color: Colours.palette.m3secondary
                        font.pointSize: Config.appearance.font.size.large
                    }
                    
                    StyledText {
                        text: qsTr("Browse Shaders...")
                        font.bold: true
                        color: Colours.palette.m3onSurface
                    }
                }

                StateLayer {
                    radius: parent.radius
                    onClicked: shaderFileDialog.open()
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
                    
                    anchors.horizontalCenter: parent.horizontalCenter

                    StyledRect {
                        anchors.fill: parent
                        anchors.margins: 2 
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