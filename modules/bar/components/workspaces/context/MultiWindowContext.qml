pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.config

Rectangle {
    id: root

    readonly property int contextWidth: Config.bar.workspaces.windowContextWidth
    readonly property int baseRadius: Appearance.rounding.normal
    readonly property int hPadding: Appearance.padding.small
    readonly property int sideMargin: Appearance.padding.large
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
    implicitWidth: root.popupActive && Niri.wsContextAnchor && root.activated ? root.contextWidth - root.sideMargin + root.hPadding : 0
    implicitHeight: root.popupActive && Niri.wsContextAnchor && root.activated ? windowsColumn.height + root.hPadding * 4 : 0

    Behavior on border.color {
        ColorAnim {}
    }

    clip: true

    anchors.left: parent.left
    anchors.leftMargin: root.sideMargin
    anchors.verticalCenter: parent.verticalCenter

    Behavior on implicitWidth {
        Anim {}
    }
    Behavior on implicitHeight {
        Anim {}
    }
    Behavior on anchors.leftMargin {
        Anim {}
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

        readonly property bool itemIsFocused: Number(Niri.focusedWindowId) === Number(modelData.id)
        readonly property bool onPrimary: root.fokus.workspace

        readonly property string displayTitle: Niri.cleanWindowTitle(modelData.title || "Untitled")
        readonly property string displaySubtitle: (modelData.app_id || "Untitled")

        color: itemIsFocused ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest

        Behavior on color {
            ColorAnim {}
        }

        // implicitHeight: column.height
        // implicitWidth: column.width

        clip: true

        implicitWidth: Niri.wsContextAnchor ? column.width : 0
        implicitHeight: root.popupActive && Niri.wsContextAnchor && root.activated ? root.itemH : 0

        Behavior on implicitHeight {
            Anim {}
        }
        Behavior on implicitWidth {
            Anim {}
        }

        radius: Appearance.rounding.small / 2

        // anchors.left: parent.left
        Layout.leftMargin: root.hPadding * 2

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) {
                    Niri.focusWindow(multiWindowContent.modelData.id);
                }
            }
        }

        RowLayout {
            id: column

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Appearance.padding.small
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                color: multiWindowContent.itemIsFocused ? Colours.palette.m3tertiary : Colours.palette.m3tertiaryContainer
                Layout.alignment: Qt.AlignVCenter

                Behavior on color {
                    ColorAnim {}
                }
                radius: root.baseRadius
                Layout.preferredHeight: root.itemH / 2
                Layout.preferredWidth: root.itemH / 2

                AnimatedText {
                    id: tekst
                    Layout.alignment: Qt.AlignVCenter

                    anchors.centerIn: parent
                    text: multiWindowContent.index + 1
                    font.pointSize: Appearance.font.size.ultraSmall
                    font.family: Appearance.font.family.mono
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
                    font.pointSize: Appearance.font.size.extraSmall
                    font.italic: multiWindowContent.itemIsFocused
                    color: multiWindowContent.itemIsFocused ? Colours.palette.m3onPrimary : (multiWindowContent.onPrimary ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurfaceVariant)
                }

                Rectangle {
                    implicitWidth: classText.width + Appearance.padding.small * 2
                    implicitHeight: classText.height
                    color: multiWindowContent.itemIsFocused ? Colours.palette.m3tertiary : "transparent"

                    radius: root.baseRadius / 2

                    Behavior on color {
                        ColorAnim {}
                    }

                    AnimatedText {
                        id: classText

                        anchors.centerIn: parent

                        text: multiWindowContent.displaySubtitle
                        font.pointSize: Appearance.font.size.ultraSmall
                        font.family: Appearance.font.family.mono
                        font.bold: multiWindowContent.itemIsFocused
                        color: multiWindowContent.itemIsFocused ? Colours.palette.m3onTertiary : Colours.palette.m3tertiaryContainer
                    }
                }

                // AnimatedText {
                //     text: multiWindowContent.displaySubtitle
                //     font.pointSize: Appearance.font.size.ultraSmall
                //     font.family: Appearance.font.family.mono
                //     font.bold: multiWindowContent.itemIsFocused
                //     color: multiWindowContent.itemIsFocused ? Colours.palette.m3onPrimary : Colours.palette.m3tertiaryContainer
                // }
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.emphasized
    }

    component ColorAnim: ColorAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.emphasized
    }

    // Local reusable StyledText with common props
    component AnimatedText: StyledText {
        Layout.preferredWidth: root.textWidth - root.sideMargin * 3
        animate: true
        elide: Text.ElideRight

        Behavior on color {
            ColorAnim {}
        }

        Behavior on font.pointSize {
            Anim {}
        }
    }
}
