pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import QtQuick
import Quickshell.Widgets

Item {
    id: iconItem
    anchors.horizontalCenter: parent.horizontalCenter
    property var windowData // main window in group
    property int windowCount // number of grouped windows
    property var groupWindows // array of windows in group
    property bool isFocused // am I focused right now?
    property bool useImageIcon // which kind?
    property bool isWsFocused // is current ws this?

    property bool groupIconsByApp: Config.bar.workspaces.groupIconsByApp
    property int currentGroupIndex: 0

    property bool popupActive: (Niri.wsAnchorItem === iconItem)

    signal requestPopup(var groupWindows, var iconItem)

    width: iconLoader.implicitWidth
    height: iconLoader.implicitHeight

    // Choose icon type

    Loader {
        id: iconLoader
        anchors.horizontalCenter: parent.horizontalCenter
        sourceComponent: iconItem.useImageIcon ? imageIconComp : materialIconComp
        property var windowData: iconItem.windowData
        property var windowCount: iconItem.windowCount
        anchors.margins: Appearance.padding.small
        Behavior on height {}

        // SubtlePulseAnim {
        //     targetComponent: iconLoader.item
        //     propertyToAnimate: "scale"
        // }
    }

    Component {
        id: imageIconComp

        Rectangle {
            implicitHeight: Config.bar.workspaces.windowIconSize + Config.bar.workspaces.windowIconGap
            implicitWidth: Config.bar.workspaces.windowIconSize

            color: "transparent"
            radius: Appearance.rounding.small / 2

            IconImage {
                anchors.centerIn: parent

                property var windowData: iconItem.windowData
                property int windowCount: iconItem.windowCount
                implicitSize: iconItem.isFocused && iconItem.isWsFocused ? Config.bar.workspaces.windowIconSize : Config.bar.workspaces.windowIconSize - Appearance.padding.small

                source: Icons.getAppIcon(windowData.app_id ?? "", "image-missing")

                Behavior on implicitSize {
                    Anim {}
                }

                WindowGroupBadge {
                    groupIconsByApp: iconItem.groupIconsByApp
                    windowCount: iconItem.windowCount
                    isWsFocused: iconItem.isWsFocused
                    isFocused: iconItem.isFocused
                    popupActive: iconItem.popupActive
                }
            }
        }
    }

    Component {
        id: materialIconComp

        StyledRect {
            // implicitHeight: Config.bar.workspaces.windowIconSize
            implicitHeight: Config.bar.workspaces.windowIconSize + Config.bar.workspaces.windowIconGap
            implicitWidth: Config.bar.workspaces.windowIconSize

            // color: iconItem.isFocused ? Colours.palette.m3primaryContainer : "transparent"
            // radius: Appearance.rounding.small / 2

            MaterialIcon {

                anchors.centerIn: parent

                property var windowData: iconItem.windowData
                property int windowCount: iconItem.windowCount
                font.pixelSize: (iconItem.isFocused && iconItem.isWsFocused) ? Config.bar.workspaces.windowIconSize : Config.bar.workspaces.windowIconSize - Appearance.padding.small
                grade: 0
                text: Icons.getAppCategoryIcon(windowData.app_id, "help_center")
                color: iconItem.popupActive ? Colours.palette.m3tertiary : (iconItem.isWsFocused ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant)

                Behavior on font.pixelSize {
                    Anim {}
                }

                WindowGroupBadge {
                    groupIconsByApp: iconItem.groupIconsByApp
                    windowCount: iconItem.windowCount
                    isWsFocused: iconItem.isWsFocused
                    isFocused: iconItem.isFocused
                    popupActive: iconItem.popupActive
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {

            // Fix: Accept groupWindows with length > 1, even if not JS Array
            if (mouse.button === Qt.LeftButton && iconItem.windowData && iconItem.groupIconsByApp && iconItem.groupWindows && iconItem.groupWindows.length > 1) {
                // Use groupWindows as an array-like object
                let idx = -1;
                // QML list objects may not support .findIndex, so fallback to manual search
                for (let i = 0; i < iconItem.groupWindows.length; ++i) {
                    if (iconItem.groupWindows[i].id === iconItem.windowData.id) {
                        idx = i;
                        break;
                    }
                }
                if (idx === -1) {}
                let nextIdx = (idx + 1) % iconItem.groupWindows.length;
                iconItem.currentGroupIndex = nextIdx;
                if (iconItem.groupWindows[nextIdx]) {
                    Niri.focusWindow(iconItem.groupWindows[nextIdx].id);
                }
            } else if (mouse.button === Qt.LeftButton && iconItem.windowData) {
                // Single icon or group with 1 window
                if (iconItem.windowData && iconItem.windowData.id) {
                    Niri.focusWindow(iconItem.windowData.id);
                }
            }
            if (iconItem.groupIconsByApp && mouse.button === Qt.RightButton && iconItem.groupWindows) {
                iconItem.requestPopup(iconItem.groupWindows, iconItem);
                console.log(iconItem.groupWindows[0].app_id);
            }
        }
    }

    component WindowGroupBadge: Item {
        id: badge
        property bool groupIconsByApp: false
        property int windowCount: 1
        property bool isWsFocused: false
        property bool isFocused: false
        property bool popupActive: false
        anchors.fill: parent

        Loader {
            active: iconItem.groupIconsByApp
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: badge.isFocused ? 0 : -Appearance.padding.small / 2

            sourceComponent: Rectangle {
                id: groupBadge
                // Component API: these properties need to be set by the parent

                visible: (badge.windowCount > 1)
                color: badge.isWsFocused ? Colours.palette.m3tertiary : Colours.palette.m3tertiaryContainer

                radius: Appearance.rounding.small

                width: Appearance.padding.larger
                height: Appearance.padding.larger

                Text {
                    anchors.centerIn: parent
                    text: badge.windowCount
                    color: badge.isWsFocused ? Colours.palette.m3onTertiary : Colours.palette.m3onTertiaryContainer
                    font.pixelSize: 9
                }
            }
        }
    }

    component SubtlePulseAnim: SequentialAnimation {
        id: seqAnim
        property var targetComponent: null
        property var propertyToAnimate: "scale"
        property real toValue: 1.05 // The value to animate to

        // The animation only runs when the target is focused
        running: targetComponent && iconItem.isFocused && iconItem.isWsFocused
        loops: Animation.Infinite

        // Animate out
        PropertyAnimation {
            target: seqAnim.targetComponent
            property: seqAnim.propertyToAnimate
            to: seqAnim.toValue
            duration: Appearance.anim.durations.extraLarge
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
        // Animate back in
        PropertyAnimation {
            target: seqAnim.targetComponent
            property: seqAnim.propertyToAnimate
            to: 1.0
            duration: Appearance.anim.durations.extraLarge
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.small
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
    }
}
