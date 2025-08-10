pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var lock
    readonly property list<string> timeComponents: Time.format(Config.services.useTwelveHourClock ? "hh:mm:A" : "hh:mm").split(":")

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumWidth: Config.lock.sizes.centerWidth

    spacing: Appearance.spacing.large * 2

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: Appearance.spacing.large
        spacing: Appearance.spacing.small

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: root.timeComponents[0]
            color: Colours.palette.m3secondary
            font.pointSize: Appearance.font.size.extraLarge * 3
            font.bold: true
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: ":"
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.extraLarge * 3
            font.bold: true
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: root.timeComponents[1]
            color: Colours.palette.m3secondary
            font.pointSize: Appearance.font.size.extraLarge * 3
            font.bold: true
        }

        Loader {
            Layout.leftMargin: Appearance.spacing.normal
            Layout.alignment: Qt.AlignVCenter

            asynchronous: true
            active: Config.services.useTwelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: root.timeComponents[2] ?? ""
                color: Colours.palette.m3primary
                font.pointSize: Appearance.font.size.extraLarge * 2
                font.bold: true
            }
        }
    }

    StyledClippingRect {
        Layout.alignment: Qt.AlignHCenter

        implicitWidth: Config.lock.sizes.centerWidth / 2
        implicitHeight: Config.lock.sizes.centerWidth / 2

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.full

        MaterialIcon {
            anchors.centerIn: parent

            text: "person"
            fill: 1
            grade: 200
            font.pointSize: Math.floor(Config.lock.sizes.centerWidth / 4)
        }

        CachingImage {
            id: pfp

            anchors.fill: parent
            path: `${Paths.stringify(Paths.home)}/.face`
        }
    }

    StyledRect {
        Layout.alignment: Qt.AlignHCenter

        implicitWidth: Config.lock.sizes.centerWidth * 0.8
        implicitHeight: input.implicitHeight + Appearance.padding.small * 2

        color: Colours.palette.m3surfaceContainer
        radius: Appearance.rounding.full

        focus: true
        onActiveFocusChanged: {
            if (!activeFocus)
                forceActiveFocus();
        }

        Keys.onPressed: event => root.lock.pam.handleKey(event)

        RowLayout {
            id: input

            anchors.fill: parent
            anchors.margins: Appearance.padding.small
            spacing: Appearance.spacing.normal

            MaterialIcon {
                Layout.leftMargin: Appearance.padding.smaller
                text: "lock"
            }

            ListView {
                id: passwordList

                Layout.fillWidth: true
                implicitHeight: Appearance.font.size.normal

                orientation: Qt.Horizontal
                clip: true
                spacing: Appearance.spacing.small / 2
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: count ? width - implicitHeight * 2 : 0
                currentIndex: count - 1

                model: ScriptModel {
                    values: root.lock.pam.buffer
                }

                delegate: StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: passwordList.implicitHeight

                    color: Colours.palette.m3onSurface
                    radius: Appearance.rounding.small / 2
                }

                add: Transition {
                    Anim {
                        property: "scale"
                        from: 0
                        to: 1
                        duration: Appearance.anim.durations.expressiveFastSpatial
                        easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                    }
                }

                remove: Transition {
                    Anim {
                        property: "scale"
                        to: 0.5
                    }
                    Anim {
                        property: "opacity"
                        to: 0
                    }
                }

                highlightFollowsCurrentItem: false
                highlight: Item {
                    x: passwordList.currentItem?.x ?? 0

                    Behavior on x {
                        Anim {}
                    }
                }
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: enterIcon.implicitHeight + Appearance.padding.small * 2

                color: root.lock.pam.buffer ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                radius: Appearance.rounding.full

                StateLayer {
                    color: root.lock.pam.buffer ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    function onClicked(): void {
                        root.lock.pam.start();
                    }
                }

                MaterialIcon {
                    id: enterIcon

                    anchors.centerIn: parent
                    text: "arrow_forward"
                    color: root.lock.pam.buffer ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    font.weight: 500
                }
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
