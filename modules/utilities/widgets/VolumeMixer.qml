pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import "../../../config"
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Config.appearance.spacing.small

    // Get audio streams (apps playing audio)
    readonly property var streams: Pipewire.nodes.values.filter(node =>
        node.isStream && node.audio && node.audio.volume !== undefined
    )

    StyledText {
        text: qsTr("Volume Mixer")
        font.weight: 600
        font.pointSize: Config.appearance.font.size.normal
        color: Colours.palette.m3onSurface
    }

    // Master volume
    VolumeMixerEntry {
        Layout.fillWidth: true
        label: qsTr("Master")
        icon: Audio.muted ? "volume_off" : "volume_up"
        volume: Audio.volume
        muted: Audio.muted
        onVolumeRequested: newVal => Audio.setVolume(newVal)
        onMuteRequested: newVal => {
            if (Audio.sink?.audio)
                Audio.sink.audio.muted = newVal
        }
    }

    // Microphone
    VolumeMixerEntry {
        Layout.fillWidth: true
        visible: Audio.source !== null
        label: qsTr("Microphone")
        icon: Audio.sourceMuted ? "mic_off" : "mic"
        volume: Audio.sourceVolume
        muted: Audio.sourceMuted
        onVolumeRequested: newVal => Audio.setSourceVolume(newVal)
        onMuteRequested: newVal => {
            if (Audio.source?.audio)
                Audio.source.audio.muted = newVal
        }
    }

    // Separator
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: Config.appearance.spacing.small
        Layout.bottomMargin: Config.appearance.spacing.small
        height: 1
        color: Colours.palette.m3outlineVariant
        visible: streamRepeater.count > 0
    }

    // Per-app streams
    Repeater {
        id: streamRepeater
        model: root.streams

        VolumeMixerEntry {
            required property PwNode modelData

            Layout.fillWidth: true
            label: modelData.name || modelData.description || qsTr("Unknown")
            icon: modelData.audio?.muted ? "volume_off" : "speaker"
            volume: modelData.audio?.volume ?? 0
            muted: modelData.audio?.muted ?? false
            onVolumeRequested: newVal => {
                if (modelData.audio)
                    modelData.audio.volume = newVal
            }
            onMuteRequested: newVal => {
                if (modelData.audio)
                    modelData.audio.muted = newVal
            }
        }
    }

    // Empty state
    StyledText {
        visible: streamRepeater.count === 0
        text: qsTr("No apps playing audio")
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Config.appearance.font.size.small
    }

    PwObjectTracker {
        objects: root.streams
    }

    component VolumeMixerEntry: RowLayout {
        id: entry

        required property string label
        required property string icon
        required property real volume
        required property bool muted

        signal volumeRequested(real newVal)
        signal muteRequested(bool newVal)

        spacing: Config.appearance.spacing.small

        // Mute button
        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: iconText.implicitHeight + Config.appearance.padding.small * 2
            radius: Config.appearance.rounding.small
            color: entry.muted ? Colours.palette.m3errorContainer : "transparent"

            MaterialIcon {
                id: iconText
                anchors.centerIn: parent
                text: entry.icon
                color: entry.muted ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurface
                font.pointSize: Config.appearance.font.size.normal
            }

            StateLayer {
                radius: parent.radius
                function onClicked(): void {
                    entry.muteRequested(!entry.muted)
                }
            }
        }

        // Label and slider
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                text: entry.label
                font.pointSize: Config.appearance.font.size.small
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            CustomMouseArea {
                Layout.fillWidth: true
                implicitHeight: Config.appearance.padding.normal * 2

                onWheel: event => {
                    const delta = event.angleDelta.y > 0 ? 0.05 : -0.05
                    entry.volumeRequested(Math.max(0, Math.min(1, entry.volume + delta)))
                }

                StyledSlider {
                    anchors.fill: parent
                    value: entry.volume
                    onMoved: entry.volumeRequested(value)
                }
            }
        }

        // Volume percentage
        StyledText {
            text: `${Math.round(entry.volume * 100)}%`
            font.pointSize: Config.appearance.font.size.small
            font.family: Config.appearance.font.family.mono
            color: Colours.palette.m3onSurfaceVariant
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
        }
    }
}
