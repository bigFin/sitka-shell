pragma ComponentBehavior: Bound

import qs.widgets
import qs.services
import qs.utils
import qs.config
import QtQuick

Item {
    id: root

    required property Brightness.Monitor monitor
    property color colour: Colours.palette.m3primary
    readonly property Item child: child

    implicitWidth: child.implicitWidth
    implicitHeight: child.implicitHeight

    Item {
        id: child

        property Item current: text1

        anchors.centerIn: parent

        clip: true
        // Arrange horizontally: icon left, text right
        implicitWidth: icon.implicitWidth + current.implicitWidth + current.anchors.leftMargin
        implicitHeight: Math.max(icon.implicitHeight, current.implicitHeight)

        MaterialIcon {
            id: icon

            animate: true
            text: Icons.getAppCategoryIcon(Niri.focusedWindowClass, "desktop_windows")
            color: root.colour

            anchors.verticalCenter: parent.verticalCenter
        }

        Title {
            id: text1
        }

        Title {
            id: text2
        }

        TextMetrics {
            id: metrics

            text: Niri.focusedWindowTitle ?? qsTr("Desktop")
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            elide: Qt.ElideTop
            elideWidth: root.width - icon.width - text1.anchors.leftMargin

            onTextChanged: {
                const next = child.current === text1 ? text2 : text1;
                next.text = elidedText;
                child.current = next;
            }
            onElideWidthChanged: child.current.text = elidedText
        }

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    }

    component Title: StyledText {
        id: text

        anchors.verticalCenter: icon.verticalCenter
        anchors.left: icon.right
        anchors.leftMargin: Appearance.spacing.small

        font.pointSize: metrics.font.pointSize
        font.family: metrics.font.family
        color: root.colour
        opacity: child.current === this ? 1 : 0

        width: implicitWidth
        height: implicitHeight

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }

}