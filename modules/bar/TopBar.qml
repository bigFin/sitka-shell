pragma ComponentBehavior: Bound

import qs.components
import qs.services
import "../../config"
import "../../utils/scripts/dashboardData.js" as DashboardData
import Quickshell
import Quickshell.Services.UPower
import QtQuick

StyledRect {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    readonly property var workspaces: WorkspaceModel.getWorkspacesForOutput(screen.name)

    enableFillets: false
    color: Colours.tPalette.m3surface
    ditherRelief: 0.35

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Colours.palette.m3outline
    }

    // Keep the empty centre inert, not a dashboard hover/drag target.
    MouseArea { anchors.fill: parent; hoverEnabled: true }

    Keycap {
        id: apps
        anchors.left: parent.left
        anchors.leftMargin: 4
        height: parent.height
        width: visible ? 56 : 0
        visible: Config.launcher.enabled
        label: qsTr("Apps")
        description: qsTr("Open launcher")
        selected: root.visibilities.launcher
        onTriggered: root.visibilities.setDrawer("launcher", !root.visibilities.launcher, "explicit")
    }

    ListView {
        id: strip
        anchors.left: apps.right
        anchors.leftMargin: 4
        anchors.top: parent.top
        height: parent.height
        width: Math.max(0, Math.min(count * 30, rightGroup.x - x - 8))
        orientation: ListView.Horizontal
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        model: root.workspaces
        currentIndex: root.workspaces.findIndex(ws => ws.is_active)
        highlightMoveDuration: 0
        delegate: Keycap {
            required property int index
            required property var modelData
            width: 30
            height: strip.height
            label: String(index + 1)
            selected: modelData.is_active
            description: qsTr("Workspace %1").arg(modelData.name || label)
            // Niri's CLI takes a name or a one-based *position*, not its internal ID.
            onTriggered: WMService.switchToWorkspace(WMService.isNiri ? (modelData.name || label) : modelData.id)
        }
    }

    Row {
        id: rightGroup
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        // Use the full workspace strip and widest stale readings as the fit
        // budget, never the current sample or the already-clipped strip width.
        readonly property real requestedWidth: (Config.bar.telemetry.showCpu ? metrics.advanceWidth("CPU 100% stale") + spacing : 0)
            + (Config.bar.telemetry.showMemory ? metrics.advanceWidth("RAM 100% stale") + spacing : 0)
        readonly property real room: root.width - anchors.rightMargin - clock.width - 8 - strip.x - strip.count * 30
        readonly property bool canShow: root.visible && root.height > 0 && !!root.Window.window?.visible
            && room >= Math.ceil(requestedWidth)

        FontMetrics { id: metrics; font: clock.font }

        Loader {
            active: rightGroup.canShow && Config.bar.telemetry.showCpu
            visible: active
            sourceComponent: Reading {
                domain: "cpu"
                text: "CPU " + DashboardData.percent(SystemUsage.cpuPerc, SystemUsage.cpuState)
            }
        }
        Loader {
            active: rightGroup.canShow && Config.bar.telemetry.showMemory
            visible: active
            sourceComponent: Reading {
                domain: "memory"
                text: "RAM " + DashboardData.percent(SystemUsage.memPerc, SystemUsage.memoryState)
            }
        }
        Loader {
            id: battery
            // Never evict CPU/RAM or reserve space for a nonexistent battery.
            readonly property real room: rightGroup.room - Math.ceil(rightGroup.requestedWidth) - rightGroup.spacing
            active: Config.bar.telemetry.showBattery && rightGroup.canShow && room >= Math.ceil(metrics.advanceWidth("BAT 100% charge"))
            visible: !!item && item.text !== ""
            sourceComponent: StyledText {
                objectName: "batteryReading"
                font: clock.font
                color: Colours.palette.m3onSurface
                text: {
                    const dev = UPower.displayDevice;
                    if (!dev?.ready || !dev.isLaptopBattery || !dev.isPresent)
                        return "";
                    const reading = DashboardData.battery(dev, UPowerDeviceState);
                    return reading.rate && Math.ceil(metrics.advanceWidth(reading.rate)) <= battery.room ? reading.rate : reading.label;
                }
            }
        }
        StyledText {
            id: clock
            text: Time.format((root.width >= 480 ? "ddd  " : "") + (Config.services.useTwelveHourClock ? "h:mm AP" : "HH:mm"))
            font.family: Config.appearance.font.family.mono
            font.pointSize: 10
            color: Colours.palette.m3onSurface
        }
    }

    component Reading: StyledText {
        required property string domain
        font: clock.font
        color: Colours.palette.m3onSurface
        Component.onCompleted: SystemUsage.addRef(domain)
        Component.onDestruction: SystemUsage.removeRef(domain)
    }

    component Keycap: MouseArea {
        id: key
        required property string label
        required property string description
        required property bool selected
        signal triggered()
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: description
        Accessible.onPressAction: triggered()
        onClicked: triggered()

        StyledRect {
            anchors.fill: parent
            anchors.margins: 2
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            enableFillets: false
            color: key.selected ? Colours.palette.m3primary : key.containsMouse ? Colours.palette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainer
            ditherRelief: key.pressed ? -0.5 : 0.5
            Rectangle {
                width: parent.width
                height: 1
                color: key.selected ? Colours.palette.m3onPrimary : Colours.palette.m3outline
                opacity: 0.65
            }
        }
        StyledText {
            anchors.centerIn: parent
            text: key.label
            font.family: Config.appearance.font.family.mono
            font.pointSize: 10
            font.bold: key.selected
            color: key.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
        }
    }
}
