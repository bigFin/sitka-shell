pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.services
import "../../config"
import "widgets" as Widgets
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right

    implicitWidth: content.implicitWidth + Config.appearance.padding.large * 2
    radius: Config.appearance.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Config.appearance.padding.large
        spacing: Config.appearance.spacing.large

        // App Dock at top
        Widgets.AppDock {
            Layout.fillWidth: true
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
        }

        // Quick Toggles
        Widgets.QuickToggles {
            Layout.fillWidth: true
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
        }

        // WiFi Networks
        Widgets.WifiNetworks {
            Layout.fillWidth: true
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
        }

        // Bluetooth Devices
        Widgets.BluetoothDevices {
            Layout.fillWidth: true
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
        }

        // Volume Mixer
        Widgets.VolumeMixer {
            Layout.fillWidth: true
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
        }

        // Pomodoro Timer
        Widgets.PomodoroTimer {
            Layout.fillWidth: true
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.palette.m3outlineVariant
        }

        // Todo List
        Widgets.TodoList {
            Layout.fillWidth: true
        }

        // Spacer
        Item {
            Layout.fillHeight: true
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }

    component Anim: NumberAnimation {
        duration: Config.appearance.anim.durations.expressiveDefaultSpatial
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
    }
}
