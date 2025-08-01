pragma ComponentBehavior: Bound

import qs.widgets
import qs.services
import qs.utils
import qs.config
import QtQuick

Item {
    id: root

    property color classColour: Colours.palette.m3primary
    property color titleColour: Colours.palette.m3secondary // Pick a suitable palette color
    readonly property Item child: child

    implicitWidth: child.implicitWidth
    implicitHeight: child.implicitHeight

    Item {
        id: child

        property Item current: textRow1

        anchors.left: parent.left

        clip: true
        implicitWidth: icon.implicitWidth + current.implicitWidth + current.anchors.leftMargin
        implicitHeight: Math.max(icon.implicitHeight, current.implicitHeight)

        MaterialIcon {
            id: icon

            animate: true
            text: Icons.getAppCategoryIcon(Niri.focusedWindowClass, "desktop_windows")
            color: root.classColour

            anchors.verticalCenter: parent.verticalCenter
        }

        // Row for two-part colored text
        TitleRow {
            id: textRow1
        }
        TitleRow {
            id: textRow2
        }

        // Elision logic for both parts
        TextMetrics {
            id: metrics

            property string classPart: Niri.focusedWindowClass || ""
            property string titlePart: Niri.focusedWindowTitle || "Hi!"
            property string separator: " -> "

            text: classPart + separator + titlePart
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            elide: Qt.ElideRight
            elideWidth: root.width - icon.width + textRow1.anchors.leftMargin

            // Helper to split elided text into two parts
            function splitElidedText() {
                // Try to split at the first occurrence of separator
                let elided = elidedText;
                let sepIdx = elided.indexOf(separator);
                if (sepIdx === -1) {
                    // Fallback: all in class, empty title
                    return { classPart: elided, titlePart: "" };
                }
                return {
                    classPart: elided.substring(0, sepIdx) + separator,
                    titlePart: elided.substring(sepIdx + separator.length)
                };
            }

            onTextChanged: {
                const next = child.current === textRow1 ? textRow2 : textRow1;
                const parts = splitElidedText();
                next.classText = parts.classPart;
                next.titleText = parts.titlePart;
                Qt.callLater(() => {
                    child.current = next;
                });
            }
            onElideWidthChanged: {
                const parts = splitElidedText();
                // child.current.text = parts.classPart + parts.titlePart;
                child.current.classText = parts.classPart;
                child.current.titleText = parts.titlePart;
            }
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

    // Row of two colored StyledText elements
    component TitleRow: Row {
        id: row

        property string classText: ""
        property string titleText: ""

        anchors.verticalCenter: icon.verticalCenter
        anchors.left: icon.right
        anchors.leftMargin: Appearance.spacing.small

        spacing: 2

        StyledText {
            text: row.classText
            font.pointSize: metrics.font.pointSize
            font.family: metrics.font.family
            color: root.classColour
            opacity: child.current === row ? 1 : 0

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
        StyledText {
            text: row.titleText
            font.pointSize: metrics.font.pointSize
            font.family: metrics.font.family
            color: root.titleColour
            opacity: child.current === row ? 1 : 0

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
}