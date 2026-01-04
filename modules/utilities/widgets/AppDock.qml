pragma ComponentBehavior: Bound

import qs.components
import qs.services
import "../../../config"
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Sitka
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Config.appearance.spacing.small

    // Helper to find desktop entry by ID
    function findEntryById(appId) {
        const apps = DesktopDatabase.applications
        for (let i = 0; i < apps.length; i++) {
            if (apps[i].id === appId || apps[i].id === appId + ".desktop") {
                return apps[i]
            }
        }
        // Fallback: try heuristic lookup
        return DesktopEntries.heuristicLookup(appId)
    }

    // Pinned apps storage
    PersistentProperties {
        id: storage
        reloadableId: "appDock"

        property string pinnedJson: '["firefox", "org.gnome.Nautilus", "code", "discord"]'
    }

    // Parse pinned app IDs
    readonly property var pinnedIds: {
        try {
            return JSON.parse(storage.pinnedJson)
        } catch (e) {
            return []
        }
    }

    // Get running windows grouped by app
    readonly property int storeVersion: WindowStore.version
    readonly property var runningApps: {
        void storeVersion
        const apps = {}
        for (let i = 0; i < WindowStore.activeWindowCount; i++) {
            const win = WindowStore.windowBuffer[i]
            if (win && win.valid) {
                const appId = win.appId || win.title || "unknown"
                if (!apps[appId]) {
                    apps[appId] = {
                        id: appId,
                        title: win.title,
                        windows: []
                    }
                }
                apps[appId].windows.push(win)
            }
        }
        return Object.values(apps)
    }

    // Get pinned apps that aren't running
    readonly property var pinnedNotRunning: pinnedIds.filter(id =>
        !runningApps.some(app => app.id.toLowerCase().includes(id.toLowerCase()))
    )

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.small

        StyledText {
            text: qsTr("Apps")
            font.weight: 600
            font.pointSize: Config.appearance.font.size.normal
            color: Colours.palette.m3onSurface
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: qsTr("%1 running").arg(runningApps.length)
            font.pointSize: Config.appearance.font.size.smaller
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    // App grid
    Flow {
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.small

        // Running apps
        Repeater {
            model: root.runningApps

            DockItem {
                required property var modelData

                appId: modelData.id
                isRunning: true
                windowCount: modelData.windows.length
                onClicked: {
                    // Focus the first window of this app
                    if (modelData.windows.length > 0) {
                        WMService.focusWindow(modelData.windows[0].id)
                    }
                }
            }
        }

        // Separator if both running and pinned exist
        Rectangle {
            visible: root.runningApps.length > 0 && root.pinnedNotRunning.length > 0
            width: 1
            height: 36
            color: Colours.palette.m3outlineVariant
        }

        // Pinned apps (not running)
        Repeater {
            model: root.pinnedNotRunning

            DockItem {
                required property string modelData

                appId: modelData
                isRunning: false
                onClicked: {
                    // Launch the app
                    const entry = root.findEntryById(modelData)
                    if (entry && entry.command) {
                        Quickshell.execDetached(["app2unit", "--", ...entry.command])
                    }
                }
            }
        }
    }

    // Empty state
    StyledText {
        visible: runningApps.length === 0 && pinnedNotRunning.length === 0
        text: qsTr("No apps")
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Config.appearance.font.size.small
    }

    component DockItem: StyledRect {
        id: item

        required property string appId
        property bool isRunning: false
        property int windowCount: 0

        signal clicked()

        implicitWidth: 44
        implicitHeight: 44
        radius: Config.appearance.rounding.normal
        color: isRunning
            ? Colours.palette.m3primaryContainer
            : Colours.palette.m3surfaceContainerHigh

        // App icon
        IconImage {
            id: iconImage
            anchors.centerIn: parent
            implicitWidth: 28
            implicitHeight: 28
            source: {
                // Try to find icon for this app
                const entry = root.findEntryById(item.appId)
                if (entry?.icon) {
                    return `image://icon/${entry.icon}`
                }
                return ""
            }

            // Fallback icon if no image found
            MaterialIcon {
                anchors.centerIn: parent
                visible: iconImage.status !== Image.Ready
                text: "apps"
                color: item.isRunning
                    ? Colours.palette.m3onPrimaryContainer
                    : Colours.palette.m3onSurface
                font.pointSize: Config.appearance.font.size.large
            }
        }

        // Running indicator dot
        Rectangle {
            visible: item.isRunning
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 2
            width: 6
            height: 3
            radius: 1.5
            color: Colours.palette.m3primary
        }

        // Window count badge
        Rectangle {
            visible: item.windowCount > 1
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 2
            width: 14
            height: 14
            radius: 7
            color: Colours.palette.m3primary

            StyledText {
                anchors.centerIn: parent
                text: item.windowCount.toString()
                font.pointSize: 8
                font.weight: 600
                color: Colours.palette.m3onPrimary
            }
        }

        StateLayer {
            radius: parent.radius
            color: item.isRunning
                ? Colours.palette.m3onPrimaryContainer
                : Colours.palette.m3onSurface
            function onClicked(): void {
                item.clicked()
            }
        }

        // Tooltip
        ToolTip {
            visible: itemHover.containsMouse
            text: item.appId
        }

        MouseArea {
            id: itemHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }

    component ToolTip: StyledRect {
        id: tooltip

        required property string text

        x: parent.width + Config.appearance.spacing.small
        y: (parent.height - height) / 2

        implicitWidth: tooltipText.implicitWidth + Config.appearance.padding.normal * 2
        implicitHeight: tooltipText.implicitHeight + Config.appearance.padding.small * 2
        radius: Config.appearance.rounding.small
        color: Colours.palette.m3inverseSurface

        StyledText {
            id: tooltipText
            anchors.centerIn: parent
            text: tooltip.text
            font.pointSize: Config.appearance.font.size.small
            color: Colours.palette.m3inverseOnSurface
        }
    }
}
