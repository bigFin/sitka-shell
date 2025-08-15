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
    readonly property int textWidth: contextWidth - hPadding * 2

    required property bool onPrimary
    required property bool isFocused
    required property int itemH
    required property bool popupActive

    property bool activated: false

    Component.onCompleted: activated = true

    color: "transparent"

    anchors.left: parent.left

    required property string displayTitle
    required property string displaySubtitle

    clip: true

    implicitWidth: root.popupActive && Niri.wsContextAnchor && root.activated ? root.contextWidth + root.hPadding : 0
    // implicitHeight: root.activated && root.popupActive && Niri.wsContextAnchor ? root.itemH : 0
    implicitHeight: root.itemH

    Behavior on implicitWidth {
        Anim {
            duration: Appearance.anim.durations.large
        }
    }
    Behavior on implicitHeight {
        Anim {}
    }

    ColumnLayout {

        anchors.fill: parent
        spacing: 0

        AnimatedText {
            Layout.leftMargin: 0
            text: root.displayTitle
            font.pointSize: Appearance.font.size.extraSmall
            font.italic: root.isFocused
            color: root.onPrimary ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
        }

        Rectangle {
            implicitWidth: classText.width + Appearance.padding.small * 2
            implicitHeight: classText.height
            color: root.onPrimary ? Colours.palette.m3tertiary : "transparent"

            radius: root.baseRadius / 2

            Behavior on color {
                ColorAnim {}
            }

            AnimatedText {
                id: classText

                anchors.centerIn: parent

                text: root.displaySubtitle
                font.pointSize: Appearance.font.size.ultraSmall
                font.family: Appearance.font.family.mono
                font.bold: root.isFocused
                color: root.onPrimary ? Colours.palette.m3onTertiary : Colours.palette.m3tertiaryContainer
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
        Layout.preferredWidth: root.textWidth
        animate: true
        elide: Text.ElideRight

        Behavior on color {
            ColorAnim {}
        }

        Behavior on font.pixelSize {
            Anim {}
        }
    }
}
