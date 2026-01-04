import qs.components
import qs.services
import "../../../config"
import Quickshell
import QtQuick

StyledRect {
    id: root

    implicitWidth: row.implicitWidth + Config.appearance.padding.small * 2
    implicitHeight: icon.implicitHeight + Config.appearance.padding.small * 2

    radius: Config.appearance.rounding.full
    color: Qt.alpha(Recorder.running ? Colours.palette.m3error : Colours.palette.m3secondaryContainer, Recorder.running ? 1 : 0)

    StateLayer {
        function onClicked(): void {
            if (Recorder.running)
                Recorder.stop();
            else
                Recorder.start();
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Config.appearance.spacing.small

        MaterialIcon {
            id: icon

            anchors.verticalCenter: parent.verticalCenter

            text: Recorder.running ? "stop_circle" : "screen_record"
            color: Recorder.running ? Colours.palette.m3onError : Colours.palette.m3secondary
            font.bold: true
            font.pointSize: Config.appearance.font.size.normal
        }

        StyledText {
            visible: Recorder.running
            anchors.verticalCenter: parent.verticalCenter
            text: Recorder.formatElapsed()
            color: Colours.palette.m3onError
            font.family: Config.appearance.font.family.mono
            font.pointSize: Config.appearance.font.size.small
        }
    }

    // Blinking animation when recording
    SequentialAnimation on opacity {
        running: Recorder.running
        loops: Animation.Infinite

        NumberAnimation {
            from: 1
            to: 0.6
            duration: 500
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            from: 0.6
            to: 1
            duration: 500
            easing.type: Easing.InOutQuad
        }
    }
}
