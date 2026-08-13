pragma ComponentBehavior: Bound

import qs.components
import qs.services
import "../../config"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    width: 760
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

    RowLayout {
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.large

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Config.appearance.spacing.smaller

            StyledText {
                text: qsTr("Coding agent usage")
                color: Colours.palette.m3onSurface
                font.pointSize: Config.appearance.font.size.extraLarge
                font.weight: 600
            }

            StyledText {
                text: AgentUsage.lastUpdatedMs > 0
                    ? qsTr("Updated %1 · automatic refresh every minute").arg(Qt.formatTime(new Date(AgentUsage.lastUpdatedMs), Locale.ShortFormat))
                    : qsTr("Waiting for provider data · automatic refresh every minute")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.size.small
            }
        }

        StyledRect {
            implicitWidth: refreshLabel.implicitWidth + Config.appearance.padding.large * 2
            implicitHeight: refreshLabel.implicitHeight + Config.appearance.padding.normal * 2
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Config.appearance.rounding.full

            StyledText {
                id: refreshLabel

                anchors.centerIn: parent
                text: AgentUsage.loading ? qsTr("Refreshing…") : qsTr("Refresh")
                color: Colours.palette.m3onSurface
                font.weight: 500
            }

            StateLayer {
                disabled: AgentUsage.loading
                radius: parent.radius
                onClicked: AgentUsage.refresh()
            }
        }
    }

    Repeater {
        model: AgentUsage.providers

        delegate: StyledRect {
            id: quota

            required property var modelData

            Layout.fillWidth: true
            implicitHeight: quotaContent.implicitHeight + Config.appearance.padding.large * 2
            color: Colours.tPalette.m3surfaceContainer
            radius: Config.appearance.rounding.small

            ColumnLayout {
                id: quotaContent

                anchors.fill: parent
                anchors.margins: Config.appearance.padding.large
                spacing: Config.appearance.spacing.normal

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Config.appearance.spacing.large

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Config.appearance.spacing.smaller

                        StyledText {
                            text: quota.modelData.name
                            color: Colours.palette.m3onSurface
                            font.pointSize: Config.appearance.font.size.large
                            font.weight: 600
                        }

                        StyledText {
                            visible: quota.modelData.plan.length > 0
                            text: quota.modelData.plan
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Config.appearance.font.size.small
                        }
                    }

                    ColumnLayout {
                        spacing: 0

                        StyledText {
                            Layout.alignment: Qt.AlignRight
                            text: qsTr("%1%").arg(Math.round(100 - quota.modelData.usedPercent))
                            color: root.usageColour(quota.modelData.usedPercent)
                            font.family: Config.appearance.font.family.mono
                            font.pointSize: Config.appearance.font.size.extraLarge
                            font.weight: 600
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignRight
                            text: qsTr("remaining")
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Config.appearance.font.size.small
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 10
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
                    Layout.fillWidth: true
                    text: root.resetLabel(quota.modelData)
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Config.appearance.font.size.small
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: AgentUsage.providers.length === 0 && AgentUsage.loading
        text: qsTr("Refreshing provider data…")
        color: Colours.palette.m3onSurfaceVariant
        horizontalAlignment: Text.AlignHCenter
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.small
        visible: AgentUsage.codexError.length > 0 || AgentUsage.claudeError.length > 0

        StyledText {
            Layout.fillWidth: true
            visible: AgentUsage.codexError.length > 0
            text: qsTr("Codex: %1").arg(AgentUsage.codexError)
            color: Colours.palette.m3error
            wrapMode: Text.Wrap
        }

        StyledText {
            Layout.fillWidth: true
            visible: AgentUsage.claudeError.length > 0
            text: qsTr("Claude: %1").arg(AgentUsage.claudeError)
            color: Colours.palette.m3error
            wrapMode: Text.Wrap
        }
    }
}
