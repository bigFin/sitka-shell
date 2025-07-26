pragma ComponentBehavior: Bound

import qs.widgets
import qs.services
import qs.config
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

ClippingRectangle {
    id: root

    required property Session session

    topRightRadius: Appearance.rounding.normal
    bottomRightRadius: Appearance.rounding.normal
    color: "transparent"

    ColumnLayout {
        id: layout

        spacing: 0
        y: -root.session.activeIndex * root.height

        Pane {
            StyledText {
                anchors.centerIn: parent
                text: qsTr("Work in progress")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.extraLarge
                font.weight: 500
            }
        }

        Pane {
            StyledText {
                anchors.centerIn: parent
                text: qsTr("Work in progress")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.extraLarge
                font.weight: 500
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }

    StyledRect {
        anchors.fill: parent
        color: Colours.palette.m3surfaceContainer

        layer.enabled: true
        layer.effect: MultiEffect {
            maskSource: mask
            maskEnabled: true
            maskInverted: true
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: 0
            radius: Appearance.rounding.small
        }
    }

    component Pane: Loader {
        id: pane

        default property Item child

        asynchronous: true
        active: {
            const ly = -layout.y;
            const ty = layout.children.indexOf(this) * root.height;
            return ly + root.height > ty && ly < ty + root.height;
        }

        sourceComponent: Item {
            implicitWidth: root.width
            implicitHeight: root.height

            Item {
                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                anchors.leftMargin: 0

                children: [pane.child]
            }

            StyledRect {
                anchors.fill: parent
                color: Colours.palette.m3surfaceContainer

                layer.enabled: true
                layer.effect: MultiEffect {
                    maskSource: mask
                    maskEnabled: true
                    maskInverted: true
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }
            }
        }
    }
}
