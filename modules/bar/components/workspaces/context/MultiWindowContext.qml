pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import "../../../../../config"

Rectangle {
    id: root

    readonly property int contextWidth: Config.bar.workspaces.windowContextWidth
    readonly property int baseRadius: Config.appearance.rounding.normal
    readonly property int hPadding: Config.appearance.padding.small
    readonly property int sideMargin: Config.appearance.padding.large
    readonly property int textWidth: contextWidth - hPadding * 2

    required property var windows
    required property var fokus
    required property int itemH
    required property bool popupActive

    property bool activated: false

    Component.onCompleted: activated = true

    radius: root.baseRadius
    color: (Colours.palette.m3surfaceContainerLow)

    border.width: root.hPadding
    border.color: (root.fokus.workspace ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh)
    implicitWidth: root.popupActive && WMService.wsContextAnchor && root.activated ? root.contextWidth - root.sideMargin + root.hPadding : 0
    implicitHeight: root.popupActive && WMService.wsContextAnchor && root.activated ? windowsColumn.height + root.hPadding * 4 : 0

    Behavior on border.color {
        CAnim {
            easing.bezierCurve: Config.appearance.anim.curves.emphasized
        }
    }

    clip: true

    anchors.left: parent.left
    anchors.leftMargin: root.sideMargin
    anchors.verticalCenter: parent.verticalCenter

    Behavior on implicitWidth {
        Anim {
            easing.bezierCurve: Config.appearance.anim.curves.emphasized
        }
    }
    Behavior on implicitHeight {
        Anim {
            easing.bezierCurve: Config.appearance.anim.curves.emphasized
        }
    }
    Behavior on anchors.leftMargin {
        Anim {
            easing.bezierCurve: Config.appearance.anim.curves.emphasized
        }
    }

    ColumnLayout {
        id: windowsColumn
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.hPadding

        Repeater {
            model: root.windows
            delegate: MultiWindowContent {}
        }
    }

    component MultiWindowContent: Rectangle {
        id: multiWindowContent
        required property var modelData
        required property var index

        readonly property bool itemIsFocused: Number(WMService.focusedWindowId) === Number(modelData.id)
        readonly property bool onPrimary: root.fokus.workspace

        readonly property string displayTitle: WMService.cleanWindowTitle(modelData.title || "Untitled")
        readonly property string displaySubtitle: (modelData.app_id || "Untitled")

        color: itemIsFocused ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest

        Behavior on color {
            CAnim {
                easing.bezierCurve: Config.appearance.anim.curves.emphasized
            }
        }

        // implicitHeight: column.height
        // implicitWidth: column.width

        clip: true

        implicitWidth: WMService.wsContextAnchor ? column.width : 0
        implicitHeight: root.popupActive && WMService.wsContextAnchor && root.activated ? root.itemH : 0

        Behavior on implicitHeight {
            Anim {
                easing.bezierCurve: Config.appearance.anim.curves.emphasized
            }
        }
        Behavior on implicitWidth {
            Anim {
                easing.bezierCurve: Config.appearance.anim.curves.emphasized
            }
        }

        radius: 0

        // anchors.left: parent.left
        Layout.leftMargin: root.hPadding * 2

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) {
                    WMService.focusWindow(multiWindowContent.modelData.id);
                }
            }
        }

        RowLayout {
            id: column

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Config.appearance.padding.small
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                color: multiWindowContent.itemIsFocused ? Colours.palette.m3tertiary : Colours.palette.m3tertiaryContainer
                Layout.alignment: Qt.AlignVCenter

                Behavior on color {
                    CAnim {
                        easing.bezierCurve: Config.appearance.anim.curves.emphasized
                    }
                }
                radius: root.baseRadius
                Layout.preferredHeight: root.itemH / 2
                Layout.preferredWidth: root.itemH / 2

                AnimatedText {
                    id: tekst
                    Layout.alignment: Qt.AlignVCenter

                    anchors.centerIn: parent
                    text: multiWindowContent.index + 1
                    font.pointSize: Config.appearance.font.size.ultraSmall
                    font.family: Config.appearance.font.family.mono
                    font.bold: true
                    color: multiWindowContent.itemIsFocused ? Colours.palette.m3onTertiary : Colours.palette.m3onTertiary
                }
            }

            ColumnLayout {
                spacing: 0

                Layout.preferredWidth: root.textWidth - root.sideMargin - multiWindowContent.Layout.leftMargin * 2 - column.anchors.leftMargin

                AnimatedText {
                    Layout.alignment: Qt.AlignVCenter

                    text: multiWindowContent.displayTitle
                    font.pointSize: Config.appearance.font.size.extraSmall
                    font.italic: multiWindowContent.itemIsFocused
                    color: multiWindowContent.itemIsFocused ? Colours.palette.m3onPrimary : (multiWindowContent.onPrimary ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurfaceVariant)
                }

                Rectangle {
                    implicitWidth: classText.width + Config.appearance.padding.small * 2
                    implicitHeight: classText.height
                    color: multiWindowContent.itemIsFocused ? Colours.palette.m3tertiary : "transparent"

                    radius: 0

                    Behavior on color {
                        CAnim {
                            easing.bezierCurve: Config.appearance.anim.curves.emphasized
                        }
                    }

                    AnimatedText {
                        id: classText

                        anchors.centerIn: parent

                        text: multiWindowContent.displaySubtitle
                        font.pointSize: Config.appearance.font.size.ultraSmall
                        font.family: Config.appearance.font.family.mono
                        font.bold: multiWindowContent.itemIsFocused
                        color: multiWindowContent.itemIsFocused ? Colours.palette.m3onTertiary : Colours.palette.m3tertiaryContainer
                    }
                }

                // AnimatedText {
                //     text: multiWindowContent.displaySubtitle
                //     font.pointSize: Config.appearance.font.size.ultraSmall
                //     font.family: Config.appearance.font.family.mono
                //     font.bold: multiWindowContent.itemIsFocused
                //     color: multiWindowContent.itemIsFocused ? Colours.palette.m3onPrimary : Colours.palette.m3tertiaryContainer
                // }
            }
        }
    }

    // Local reusable StyledText with common props
    component AnimatedText: StyledText {
        Layout.preferredWidth: root.textWidth - root.sideMargin * 3
        animate: true
        elide: Text.ElideRight

        Behavior on color {
            CAnim {
                easing.bezierCurve: Config.appearance.anim.curves.emphasized
            }
        }

        Behavior on font.pointSize {
            Anim {
                easing.bezierCurve: Config.appearance.anim.curves.emphasized
            }
        }
    }
}
