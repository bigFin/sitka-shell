pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import "../../../config"
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Config.appearance.spacing.small

    // Timer state
    property int workMinutes: 25
    property int breakMinutes: 5
    property int longBreakMinutes: 15
    property int sessionsUntilLongBreak: 4

    property int currentSession: 1
    property bool isBreak: false
    property bool isRunning: false
    property int remainingSeconds: workMinutes * 60

    // Format time as MM:SS
    function formatTime(seconds: int): string {
        const mins = Math.floor(seconds / 60)
        const secs = seconds % 60
        return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
    }

    // Timer logic
    Timer {
        id: timer
        interval: 1000
        repeat: true
        running: root.isRunning

        onTriggered: {
            if (root.remainingSeconds > 0) {
                root.remainingSeconds--
            } else {
                // Timer complete
                root.isRunning = false

                if (root.isBreak) {
                    // Break finished, start new work session
                    root.isBreak = false
                    root.remainingSeconds = root.workMinutes * 60
                    // Notify
                    Quickshell.execDetached(["notify-send", "Pomodoro", "Break's over! Time to focus."])
                } else {
                    // Work session finished
                    root.currentSession++
                    root.isBreak = true

                    if ((root.currentSession - 1) % root.sessionsUntilLongBreak === 0) {
                        root.remainingSeconds = root.longBreakMinutes * 60
                        Quickshell.execDetached(["notify-send", "Pomodoro", "Great work! Take a long break."])
                    } else {
                        root.remainingSeconds = root.breakMinutes * 60
                        Quickshell.execDetached(["notify-send", "Pomodoro", "Good job! Take a short break."])
                    }
                }
            }
        }
    }

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.small

        StyledText {
            text: qsTr("Pomodoro")
            font.weight: 600
            font.pointSize: Config.appearance.font.size.normal
            color: Colours.palette.m3onSurface
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: qsTr("Session %1").arg(root.currentSession)
            font.pointSize: Config.appearance.font.size.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    // Timer display
    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: timerContent.implicitHeight + Config.appearance.padding.large * 2
        radius: Config.appearance.rounding.normal
        color: root.isBreak
            ? Colours.palette.m3tertiaryContainer
            : Colours.palette.m3primaryContainer

        ColumnLayout {
            id: timerContent
            anchors.centerIn: parent
            spacing: Config.appearance.spacing.small

            // Mode label
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.isBreak ? qsTr("Break Time") : qsTr("Focus Time")
                font.pointSize: Config.appearance.font.size.small
                color: root.isBreak
                    ? Colours.palette.m3onTertiaryContainer
                    : Colours.palette.m3onPrimaryContainer
            }

            // Time display
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.formatTime(root.remainingSeconds)
                font.family: Config.appearance.font.family.mono
                font.pointSize: Config.appearance.font.size.extraLarge * 1.5
                font.weight: 600
                color: root.isBreak
                    ? Colours.palette.m3onTertiaryContainer
                    : Colours.palette.m3onPrimaryContainer
            }

            // Progress bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                Layout.leftMargin: Config.appearance.padding.large
                Layout.rightMargin: Config.appearance.padding.large
                radius: 2
                color: Qt.alpha(root.isBreak
                    ? Colours.palette.m3onTertiaryContainer
                    : Colours.palette.m3onPrimaryContainer, 0.2)

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    color: root.isBreak
                        ? Colours.palette.m3onTertiaryContainer
                        : Colours.palette.m3onPrimaryContainer

                    property int totalSeconds: root.isBreak
                        ? (((root.currentSession - 1) % root.sessionsUntilLongBreak === 0)
                            ? root.longBreakMinutes : root.breakMinutes) * 60
                        : root.workMinutes * 60

                    width: parent.width * (1 - root.remainingSeconds / totalSeconds)

                    Behavior on width {
                        NumberAnimation { duration: 200 }
                    }
                }
            }
        }
    }

    // Controls
    RowLayout {
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.small

        // Play/Pause button
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: controlIcon.implicitHeight + Config.appearance.padding.normal * 2
            radius: Config.appearance.rounding.normal
            color: Colours.palette.m3primary

            MaterialIcon {
                id: controlIcon
                anchors.centerIn: parent
                text: root.isRunning ? "pause" : "play_arrow"
                color: Colours.palette.m3onPrimary
                font.pointSize: Config.appearance.font.size.large
            }

            StateLayer {
                radius: parent.radius
                color: Colours.palette.m3onPrimary
                function onClicked(): void {
                    root.isRunning = !root.isRunning
                }
            }
        }

        // Reset button
        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: resetIcon.implicitHeight + Config.appearance.padding.normal * 2
            radius: Config.appearance.rounding.normal
            color: Colours.palette.m3surfaceContainerHigh

            MaterialIcon {
                id: resetIcon
                anchors.centerIn: parent
                text: "restart_alt"
                color: Colours.palette.m3onSurface
                font.pointSize: Config.appearance.font.size.large
            }

            StateLayer {
                radius: parent.radius
                function onClicked(): void {
                    root.isRunning = false
                    root.isBreak = false
                    root.currentSession = 1
                    root.remainingSeconds = root.workMinutes * 60
                }
            }
        }

        // Skip button
        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: skipIcon.implicitHeight + Config.appearance.padding.normal * 2
            radius: Config.appearance.rounding.normal
            color: Colours.palette.m3surfaceContainerHigh

            MaterialIcon {
                id: skipIcon
                anchors.centerIn: parent
                text: "skip_next"
                color: Colours.palette.m3onSurface
                font.pointSize: Config.appearance.font.size.large
            }

            StateLayer {
                radius: parent.radius
                function onClicked(): void {
                    root.remainingSeconds = 0
                    timer.triggered()
                }
            }
        }
    }
}
