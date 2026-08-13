pragma ComponentBehavior: Bound

import qs.components
import qs.services
import "../../../config"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    width: 380
    spacing: Config.appearance.spacing.large

    function formatDuration(milliseconds: real): string {
        const minutes = Math.max(0, Math.floor(milliseconds / 60000));
        const days = Math.floor(minutes / 1440);
        const hours = Math.floor(minutes / 60) % 24;
        const mins = minutes % 60;
        if (days > 0)
            return qsTr("%1d %2h").arg(days).arg(hours);
        if (hours > 0)
            return qsTr("%1h %2m").arg(hours).arg(mins);
        return qsTr("%1m").arg(mins);
    }

    function resetLabel(provider: var): string {
        if (provider.resetsAt > 0) {
            const reset = new Date(provider.resetsAt);
            const absolute = Qt.formatDateTime(reset, "ddd, MMM d · h:mm AP");
            return qsTr("Resets %1 · in %2").arg(absolute).arg(formatDuration(provider.resetsAt - Date.now()));
        }
        return provider.resetText || qsTr("Reset time unavailable");
    }

    function usageColour(usedPercent: real): color {
        if (usedPercent >= 90)
            return Colours.palette.m3error;
        if (usedPercent >= 70)
            return Colours.palette.m3tertiary;
        return Colours.palette.m3primary;
    }

    Component.onCompleted: AgentUsage.refresh()

    RowLayout {
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.normal

        MaterialIcon {
            text: "data_usage"
            color: Colours.palette.m3primary
            font.pointSize: Config.appearance.font.size.large
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: qsTr("Coding agent usage")
                color: Colours.palette.m3onSurface
                font.weight: 500
                font.pointSize: Config.appearance.font.size.large
            }

            StyledText {
                text: AgentUsage.lastUpdatedMs > 0 ? qsTr("Updated %1").arg(Qt.formatTime(new Date(AgentUsage.lastUpdatedMs), Locale.ShortFormat)) : qsTr("Waiting for provider data")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.size.small
            }
        }

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: refreshIcon.implicitHeight + Config.appearance.padding.small * 2
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Config.appearance.rounding.full

            MaterialIcon {
                id: refreshIcon

                anchors.centerIn: parent
                text: "refresh"
                color: Colours.palette.m3onSurface

                RotationAnimation on rotation {
                    running: AgentUsage.loading
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                }
            }

            StateLayer {
                radius: parent.radius
                enabled: !AgentUsage.loading
                onClicked: AgentUsage.refresh()
            }
        }
    }

    Repeater {
        model: AgentUsage.providers

        delegate: ColumnLayout {
            id: quota

            required property var modelData

            Layout.fillWidth: true
            spacing: Config.appearance.spacing.small

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: quota.modelData.plan ? qsTr("%1 · %2").arg(quota.modelData.name).arg(quota.modelData.plan) : quota.modelData.name
                    color: Colours.palette.m3onSurface
                    font.weight: 500
                }

                StyledText {
                    text: qsTr("%1% left").arg(Math.round(100 - quota.modelData.usedPercent))
                    color: root.usageColour(quota.modelData.usedPercent)
                    font.family: Config.appearance.font.family.mono
                    font.weight: 500
                }
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 8
                color: Colours.tPalette.m3surfaceContainerHigh
                radius: Config.appearance.rounding.full
                clip: true

                StyledRect {
                    width: parent.width * quota.modelData.usedPercent / 100
                    height: parent.height
                    color: root.usageColour(quota.modelData.usedPercent)
                    radius: parent.radius

                    Behavior on width {
                        Anim {}
                    }
                }
            }

            StyledText {
                text: root.resetLabel(quota.modelData)
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.size.small
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.smaller
        visible: AgentUsage.codexError.length > 0 || AgentUsage.claudeError.length > 0

        StyledText {
            visible: AgentUsage.codexError.length > 0
            text: qsTr("Codex: %1").arg(AgentUsage.codexError)
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.size.small
        }

        StyledText {
            visible: AgentUsage.claudeError.length > 0
            text: qsTr("Claude: %1").arg(AgentUsage.claudeError)
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Config.appearance.font.size.small
        }
    }
}
