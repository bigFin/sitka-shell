import QtQuick
import QtQuick.Controls
import qs.services
import qs.widgets
import qs.config
import QtQuick.Layouts

import "."

ColumnLayout {
    spacing: Appearance.padding.normal

    Component.onCompleted: {
        SysMonitorService.addRef();
        SysMonitorService.updateAllStats();
    }
    Component.onDestruction: {
        SysMonitorService.removeRef();
    }

    function formatNetworkSpeed(bytesPerSec) {
        if (bytesPerSec < 1024)
            return bytesPerSec.toFixed(0) + " B/s";
        else if (bytesPerSec < 1024 * 1024)
            return (bytesPerSec / 1024).toFixed(1) + " KB/s";
        else if (bytesPerSec < 1024 * 1024 * 1024)
            return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s";
        else
            return (bytesPerSec / (1024 * 1024 * 1024)).toFixed(1) + " GB/s";
    }

    function formatDiskSpeed(bytesPerSec) {
        if (bytesPerSec < 1024 * 1024)
            return (bytesPerSec / 1024).toFixed(1) + " KB/s";
        else if (bytesPerSec < 1024 * 1024 * 1024)
            return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s";
        else
            return (bytesPerSec / (1024 * 1024 * 1024)).toFixed(1) + " GB/s";
    }

    // CPU Section
    Rectangle {
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 320
        radius: Appearance.rounding.small
        color: Colours.palette.m3surfaceContainer

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.padding.large

            // TextEdit {
            //     text: "GPUS:\n" + JSON.stringify(SysMonitorService.gpus, null, 2)
            //     color: "white"
            //     font.family: "monospace"
            //     font.pointSize: 10
            //     readOnly: true
            //     selectByMouse: true
            //     wrapMode: TextEdit.Wrap
            //     width: parent.width
            // }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                spacing: Appearance.padding.normal

                StyledText {
                    text: "   CPU"
                    font.family: Appearance.font.family.mono
                    font.pointSize: Appearance.font.size.large
                    font.weight: Font.Bold
                    color: Colours.palette.m3onSurface
                    Layout.alignment: Qt.AlignVCenter
                }

                InfoBadge {
                    text: SysMonitorService.totalCpuUsage.toFixed(1) + "%"
                    badgeColor: Colours.palette.info
                    fontSize: Appearance.font.size.small
                    fontWeight: Font.Bold
                }

                InfoBadge {
                    text: SysMonitorService.cpuTemperature + "°C"
                    badgeColor: Colours.palette.warning
                    fontSize: Appearance.font.size.small
                    fontWeight: Font.Bold
                }

                Item {
                    Layout.fillWidth: true
                }

                InfoBadge {
                    width: 110
                    text: SysMonitorService.cpuCount + " cores"
                    badgeColor: Colours.palette.success
                    fontSize: Appearance.font.size.small
                    fontWeight: Font.Bold
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                GridLayout {
                    columns: 2
                    Layout.fillHeight: true
                    width: parent.parent.width
                    rowSpacing: 6
                    columnSpacing: 6

                    Repeater {
                        model: SysMonitorService.perCoreCpuUsage

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            Layout.preferredWidth: parent.parent.width
                            spacing: Appearance.padding.small

                            InfoBadge {
                                text: index
                                badgeColor: Colours.palette.m3onSurfaceVariant
                                fontSize: Appearance.font.size.small

                                width: 50
                                height: 20
                            }

                            Rectangle {
                                id: rectangul
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                Layout.preferredWidth: 60
                                radius: 3
                                color: Colours.palette.m3surfaceContainerLowest
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    width: parent.width * Math.min(1, modelData / 100)
                                    height: parent.height
                                    radius: parent.radius
                                    color: {
                                        const usage = modelData;
                                        if (usage > 80)
                                            return Colours.palette.error;
                                        if (usage > 60)
                                            return Colours.palette.warning;
                                        return Colours.palette.m3primary;
                                    }

                                    Behavior on width {
                                        NumberAnimation {
                                            //HAX
                                            from: rectangul.width * Math.min(1, SysMonitorService.perCoreCpuUsagePrev[index] / 100)
                                            duration: Appearance.anim.durations.normal
                                        }
                                    }
                                }
                            }

                            InfoBadge {
                                text: modelData ? modelData.toFixed(0) + "%" : "0%"
                                badgeColor: Colours.palette.m3onSurface
                                fontSize: Appearance.font.size.small
                                fontWeight: Font.Medium

                                width: 50
                                height: 20
                            }
                        }
                    }
                }
            }
        }
    }

    // GPU Section
    // GPU Section (Multi-GPU Support)
    ColumnLayout {
        spacing: Appearance.padding.normal

        Repeater {
            model: SysMonitorService.gpus || []

            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                radius: Appearance.rounding.small
                color: Colours.palette.m3surfaceContainer
                property var gpu: modelData

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.padding.normal

                        StyledText {
                            text: " 󰾲  GPU"
                            font.family: Appearance.font.family.mono
                            font.pointSize: Appearance.font.size.large
                            font.weight: Font.Bold
                            color: Colours.palette.m3onSurface
                            Layout.alignment: Qt.AlignVCenter
                        }

                        InfoBadge {
                            text: gpu.usage !== undefined ? gpu.usage.toFixed(1) + "%" : "N/A"
                            badgeColor: Colours.palette.info
                            fontSize: Appearance.font.size.small
                            fontWeight: Font.Bold
                        }

                        InfoBadge {
                            text: gpu.temperature !== undefined ? gpu.temperature + "°C" : "N/A"
                            badgeColor: Colours.palette.warning
                            fontSize: Appearance.font.size.small
                            fontWeight: Font.Bold
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        InfoBadge {
                            text: gpu.name ? gpu.name : "Unknown"
                            badgeColor: Colours.palette.success
                            width: 340
                            fontSize: Appearance.font.size.small
                            fontWeight: Font.Bold
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.padding.normal

                        InfoBadge {
                            width: 165
                            text: (gpu.memoryTotal) ? (gpu.memoryUsed / 1024).toFixed(0) + " GB / " + (gpu.memoryTotal / 1024).toFixed(0) + " GB" : "N/A"
                            badgeColor: Colours.palette.m3primary
                            fontSize: Appearance.font.size.small
                            fontWeight: Font.Bold
                        }

                        AnimatedBar {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 16
                            radius: 8
                            value: (gpu.memoryTotal > 0) ? (gpu.memoryUsed / gpu.memoryTotal) : 0
                            barColor: {
                                const usage = gpu.memoryTotal > 0 ? (gpu.memoryUsed / gpu.memoryTotal) : 0;
                                if (usage > 0.9)
                                    return Colours.palette.error;
                                if (usage > 0.7)
                                    return Colours.palette.warning;
                                return Colours.palette.m3primary;
                            }
                            backgroundColor: Colours.palette.m3surfaceContainerHigh
                            animationDuration: Appearance.anim.durations.normal
                        }
                    }
                }
            }
        }
    }

    // Memory & Swap Section
    Rectangle {
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        radius: Appearance.rounding.small
        color: Colours.palette.m3surfaceContainer

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: 0

            // Memory
            RowLayout {
                ColumnLayout {
                    Layout.alignment: Qt.AlignLeft
                    spacing: Appearance.padding.large

                    RowLayout {
                        spacing: Appearance.padding.normal

                        StyledText {
                            text: "   MEMORY"
                            font.family: Appearance.font.family.mono
                            font.pointSize: Appearance.font.size.large
                            font.weight: Font.Bold
                            color: Colours.palette.m3onSurface
                        }

                        InfoBadge {
                            text: SysMonitorService.totalMemoryKB > 0 ? ((SysMonitorService.usedMemoryKB / SysMonitorService.totalMemoryKB) * 100).toFixed(1) + "%" : "Null"
                            badgeColor: Colours.palette.info
                            fontSize: Appearance.font.size.small
                            fontWeight: Font.Bold
                        }
                    }
                    RowLayout {
                        InfoBadge {
                            width: 165
                            height: 24
                            text: SysMonitorService.formatSystemMemory(SysMonitorService.usedMemoryKB) + " / " + SysMonitorService.formatSystemMemory(SysMonitorService.totalMemoryKB)
                            badgeColor: Colours.palette.m3tertiary
                            fontSize: Appearance.font.size.small
                            fontWeight: Font.Black
                        }
                        AnimatedBar {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 16
                            radius: Appearance.rounding.small
                            value: SysMonitorService.totalMemoryKB > 0 ? (SysMonitorService.usedMemoryKB / SysMonitorService.totalMemoryKB) : 0
                            barColor: {
                                const usage = SysMonitorService.totalMemoryKB > 0 ? (SysMonitorService.usedMemoryKB / SysMonitorService.totalMemoryKB) : 0;
                                if (usage > 0.9)
                                    return Colours.palette.error;
                                if (usage > 0.7)
                                    return Colours.palette.warning;
                                return Colours.palette.m3tertiary;
                            }
                            backgroundColor: Colours.palette.m3surfaceContainerHigh
                            animationDuration: Appearance.anim.durations.normal
                        }
                    }
                }
            }

            // Swap
            RowLayout {
                ColumnLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: Appearance.padding.large

                    RowLayout {
                        Layout.alignment: Qt.AlignRight

                        InfoBadge {
                            text: SysMonitorService.totalSwapKB > 0 ? ((SysMonitorService.usedSwapKB / SysMonitorService.totalSwapKB) * 100).toFixed(1) + "%" : "Not available"
                            badgeColor: Colours.palette.info
                            fontSize: Appearance.font.size.small
                            fontWeight: Font.Bold
                        }

                        StyledText {
                            text: "SWAP 󰿡 "
                            font.family: Appearance.font.family.mono
                            font.pointSize: Appearance.font.size.large
                            font.weight: Font.Bold
                            color: Colours.palette.m3onSurface
                        }
                    }

                    RowLayout {
                        AnimatedBar {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 16
                            radius: Appearance.rounding.small
                            value: SysMonitorService.totalSwapKB > 0 ? (SysMonitorService.usedSwapKB / SysMonitorService.totalSwapKB) : 0
                            barColor: {
                                if (!SysMonitorService.totalSwapKB)
                                    return Qt.rgba(Colours.palette.m3onSurface.r, Colours.palette.m3onSurface.g, Colours.palette.m3onSurface.b, 0.3);
                                const usage = SysMonitorService.usedSwapKB / SysMonitorService.totalSwapKB;
                                if (usage > 0.9)
                                    return Colours.palette.error;
                                if (usage > 0.7)
                                    return Colours.palette.warning;
                                return Colours.palette.m3tertiary;
                            }
                            backgroundColor: Colours.palette.m3surfaceContainerHigh
                            animationDuration: Appearance.anim.durations.normal
                        }

                        InfoBadge {
                            width: 165
                            height: 24
                            text: SysMonitorService.totalSwapKB > 0 ? SysMonitorService.formatSystemMemory(SysMonitorService.usedSwapKB) + " / " + SysMonitorService.formatSystemMemory(SysMonitorService.totalSwapKB) : "No swap configured"
                            badgeColor: Colours.palette.m3tertiary
                            fontSize: Appearance.font.size.small
                            fontWeight: Font.Black
                        }
                    }
                }
            }
        }
    }

    // Network & Disk Section
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 80
        spacing: Appearance.padding.normal

        // Network
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.preferredHeight: 80
            radius: Appearance.rounding.small
            color: Colours.palette.m3surfaceContainer

            RowLayout {
                anchors.fill: parent

                StyledText {
                    text: "  NETWORK"
                    font.family: Appearance.font.family.mono
                    font.pointSize: Appearance.font.size.large
                    font.weight: Font.Bold
                    color: Colours.palette.m3onSurface
                    Layout.alignment: Qt.AlignHCenter
                }

                ColumnLayout {
                    spacing: Appearance.padding.small
                    Layout.alignment: Qt.AlignHCenter

                    RowLayout {
                        spacing: Appearance.padding.small

                        StyledText {
                            text: "↑"
                            font.pointSize: Appearance.font.size.small
                            font.family: Appearance.font.family.mono
                            font.weight: Font.Black
                            color: Colours.palette.info
                        }
                        InfoBadge {
                            width: 120
                            text: SysMonitorService.networkTxRate > 0 ? formatNetworkSpeed(SysMonitorService.networkTxRate) : "0 B/s"
                            badgeColor: Colours.palette.info
                            fontSize: Appearance.font.size.small
                            fontWeight: Font.Bold
                        }
                    }

                    RowLayout {
                        spacing: Appearance.padding.small

                        StyledText {
                            text: "↓"
                            font.pointSize: Appearance.font.size.small
                            font.family: Appearance.font.family.mono
                            font.weight: Font.Black
                            color: Colours.palette.success
                        }
                        InfoBadge {
                            width: 120
                            text: SysMonitorService.networkRxRate > 0 ? formatNetworkSpeed(SysMonitorService.networkRxRate) : "0 B/s"
                            badgeColor: Colours.palette.success
                            fontSize: Appearance.font.size.small
                            fontWeight: Font.Bold
                        }
                    }
                }
            }
        }

        // Disk
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.preferredHeight: 80
            radius: Appearance.rounding.small
            color: Colours.palette.m3surfaceContainer

            RowLayout {
                anchors.fill: parent

                StyledText {
                    text: "  DISK"
                    font.family: Appearance.font.family.mono
                    font.pointSize: Appearance.font.size.large
                    font.weight: Font.Bold
                    color: Colours.palette.m3onSurface
                    Layout.alignment: Qt.AlignHCenter
                }

                ColumnLayout {
                    spacing: Appearance.padding.small
                    Layout.alignment: Qt.AlignHCenter
                    RowLayout {
                        spacing: Appearance.padding.small

                        StyledText {
                            text: "W"
                            font.pointSize: Appearance.font.size.small
                            font.family: Appearance.font.family.mono
                            font.weight: Font.Black
                            color: Colours.palette.info
                        }

                        InfoBadge {
                            width: 120
                            text: formatDiskSpeed(SysMonitorService.diskWriteRate)
                            badgeColor: Colours.palette.info
                            fontSize: Appearance.font.size.small
                            fontWeight: Font.Bold
                        }
                    }

                    RowLayout {
                        spacing: Appearance.padding.small

                        StyledText {
                            text: "R"
                            font.pointSize: Appearance.font.size.small
                            font.family: Appearance.font.family.mono
                            font.weight: Font.Black
                            color: Colours.palette.success
                        }
                        InfoBadge {
                            width: 120
                            text: formatDiskSpeed(SysMonitorService.diskReadRate)
                            badgeColor: Colours.palette.success
                            fontSize: Appearance.font.size.small
                            fontWeight: Font.Bold
                        }
                    }
                }
            }
        }
    }

    component InfoBadge: Rectangle {
        id: badge
        property string text: ""
        property color badgeColor: "#e0e0e0"
        property int fontSize: 12
        property int fontWeight: Font.Bold
        // property real radius: 8
        property string fontFamily: Appearance.font.family.mono
        width: 80
        height: 24
        // radius: radius
        radius: Appearance.rounding.small
        color: Qt.rgba(badgeColor.r, badgeColor.g, badgeColor.b, 0.12)

        StyledText {
            anchors.centerIn: parent
            text: badge.text
            font.pointSize: fontSize
            font.weight: fontWeight
            color: badgeColor
            font.family: fontFamily
        }
    }

    component AnimatedBar: Rectangle {
        id: bar
        property real value: 0.0        // Value between 0 and 1
        property color barColor: "blue"
        property color backgroundColor: "#e0e0e0"
        // property real radius: 8
        property int animationDuration: 300

        width: 120
        height: 16
        color: backgroundColor

        Rectangle {
            id: fillBar
            width: bar.width * Math.min(1, Math.max(0, value))
            height: bar.height
            radius: bar.radius
            color: barColor

            Behavior on width {
                NumberAnimation {
                    duration: animationDuration
                }
            }
        }
    }
}
