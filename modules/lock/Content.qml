pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.services
import qs.config
import qs.utils
import QtQuick
import QtQuick.Layouts

GridLayout {
    id: root

    required property var lock

    anchors.fill: parent
    anchors.margins: Appearance.padding.large

    rowSpacing: Appearance.spacing.large
    columnSpacing: Appearance.spacing.large

    rows: 2
    columns: 3

    StyledRect {
        Layout.row: 0
        Layout.column: 0
        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: Appearance.rounding.small
        color: Colours.tPalette.m3surfaceContainer
    }

    StyledRect {
        Layout.row: 1
        Layout.column: 0
        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: Appearance.rounding.small
        color: Colours.tPalette.m3surfaceContainer
    }

    StyledClippingRect {
        Layout.row: 0
        Layout.column: 1
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        implicitWidth: Config.lock.sizes.faceSize
        implicitHeight: Config.lock.sizes.faceSize

        radius: Appearance.rounding.large
        color: Colours.tPalette.m3surfaceContainer

        MaterialIcon {
            anchors.centerIn: parent

            text: "person"
            fill: 1
            grade: 200
            font.pointSize: Math.floor(Config.lock.sizes.faceSize / 2)
        }

        CachingImage {
            id: pfp

            anchors.fill: parent
            path: `${Paths.stringify(Paths.home)}/.face`
        }
    }

    Input {
        Layout.row: 1
        Layout.column: 1

        lock: root.lock
    }

    StyledRect {
        Layout.row: 0
        Layout.column: 2
        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: Appearance.rounding.small
        color: Colours.tPalette.m3surfaceContainer
    }

    StyledRect {
        Layout.row: 1
        Layout.column: 2
        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: Appearance.rounding.small
        color: Colours.tPalette.m3surfaceContainer
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
