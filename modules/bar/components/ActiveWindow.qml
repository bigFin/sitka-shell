pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import "../../../config"
import QtQuick

Item {
    id: root

    required property var bar
    required property Brightness.Monitor monitor
    property color colour: Colours.palette.m3primary
    readonly property string windowClass: WMService.focusedWindowClass || "Desktop"
    readonly property string windowTitle: WMService.focusedWindowTitle || qsTr("Desktop")

    readonly property int maxHeight: {
        const otherModules = bar.children.filter(c => c.id && c.item !== this && c.id !== "spacer");
        const otherHeight = otherModules.reduce((acc, curr) => acc + curr.height, 0);
        // Length - 2 cause repeater counts as a child
        return Math.max(0, bar.height - otherHeight - bar.spacing * (bar.children.length - 1) - bar.vPadding * 2);
    }
    property Title current: text1

    clip: true
    implicitWidth: Math.max(icon.implicitWidth, current.implicitHeight)
    implicitHeight: icon.implicitHeight + current.implicitWidth + current.anchors.topMargin

    MaterialIcon {
        id: icon

        anchors.horizontalCenter: parent.horizontalCenter

        animate: true
        text: Icons.getAppCategoryIcon(root.windowClass, "desktop_windows")
        color: root.colour
    }

    Title {
        id: text1
    }

    Title {
        id: text2
    }

    TextMetrics {
        id: metrics

        text: root.windowTitle
        font.pointSize: Config.appearance.font.size.smaller
        font.family: Config.appearance.font.family.mono
        elide: Qt.ElideRight
        elideWidth: Math.max(0, root.maxHeight - icon.height)

        function swapText(): void {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            Qt.callLater(() => {
                if (next.text === metrics.elidedText)
                    root.current = next;
            });
        }

        onTextChanged: swapText()
        onElideWidthChanged: swapText()
        Component.onCompleted: text1.text = elidedText
    }

    Behavior on implicitHeight {
        Anim {
            easing.bezierCurve: Config.appearance.anim.curves.emphasized
        }
    }

    component Title: StyledText {
        id: text

        anchors.horizontalCenter: icon.horizontalCenter
        anchors.top: icon.bottom
        anchors.topMargin: Config.appearance.spacing.small

        font.pointSize: metrics.font.pointSize
        font.family: metrics.font.family
        color: root.colour
        opacity: root.current === this ? 1 : 0

        transform: Rotation {
            angle: 90
            origin.x: text.implicitHeight / 2
            origin.y: text.implicitHeight / 2
        }

        width: implicitHeight
        height: implicitWidth

        Behavior on opacity {
            Anim {}
        }
    }
}
