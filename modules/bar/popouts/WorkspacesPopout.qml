pragma ComponentBehavior: Bound

// TODO: do not forget this :D

import qs.services
import qs.utils
import "../../../config"
import QtQuick
import Quickshell.Widgets
import QtQuick.Layouts
import qs.components

StyledRect {
    id: root
    property bool useImageIcon: false

    width: Math.max(0, Config.bar.sizes.windowPreviewSize - 100)
    height: 250

    ColumnLayout {
        id: groupMenu

        anchors.fill: parent

        property bool useImageIcon: root.useImageIcon
        property color bgColor: Colours.palette.m3surfaceContainer
        property color onColor: Colours.palette.m3onSurfaceVariant

        clip: true

        // ================= Workspaces =================
        ListView {
            id: workspaces
            Layout.fillWidth: true
            model: Niri.getWorkspaceCount()
            implicitHeight: contentHeight

            // spacing: Config.appearance.spacing.small

            delegate: WorkspaceDelegate {}
        }
    }

    // =====================================================
    // =============== COMPONENTS ==========================
    // =====================================================

    // -------- WorkspaceDelegate --------------------------
    component WorkspaceDelegate: StyledRect {
        id: wsRect

        required property int index

        radius: Config.appearance.rounding.small
        color: groupMenu.bgColor
        Layout.fillWidth: true

        readonly property var windows: Niri.getWindowsByWorkspaceIndex(index)
        readonly property var groupedWindows: {
            const groups = {};
            for (const win of windows) {
                const key = win.app_id || "unknown";
                if (!groups[key])
                    groups[key] = [];
                groups[key].push(win);
            }
            return Object.entries(groups).map(([app_id, wins]) => ({
                        app_id,
                        windows: wins
                    }));
        }

        implicitHeight: col.implicitHeight
        // implicitWidth: col.implicitWidth
        implicitWidth: groupMenu.width

        ColumnLayout {
            id: col
            // spacing: Config.appearance.spacing.small
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                readonly property string wsName: {
                    const baseName = Niri.getWorkspaceNameByIndex(wsRect.index) || (wsRect.index + 1);
                    return wsRect.windows.length > 0 ? baseName : `${baseName} (empty)`;
                }
                text: wsName
                font.pointSize: Config.appearance.font.size.small
                elide: Text.ElideRight
                color: Colours.palette.m3tertiary
            }

            // -------- App Groups -----------------
            ListView {
                Layout.fillWidth: true
                model: wsRect.groupedWindows
                implicitHeight: contentHeight + spacing
                spacing: Config.appearance.spacing.small
                Layout.alignment: Qt.AlignCenter
                Layout.leftMargin: Config.appearance.spacing.small

                Behavior on implicitHeight {
                    Anim {}
                }

                delegate: AppGroupDelegate {}
            }
        }
    }

    // -------- AppGroup --------------------------
    component AppGroupDelegate: StyledRect {
        id: appGroup

        required property var modelData // { app_id, windows }
        readonly property bool isFocused: Number(Niri.focusedWorkspaceId) === Number(modelData.workspace_id)

        radius: Config.appearance.rounding.small
        color: isFocused ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

        clip: true

        implicitHeight: appCol.implicitHeight
        implicitWidth: groupMenu.width - Config.appearance.spacing.small * 2

        ColumnLayout {
            id: appCol
            anchors.fill: parent

            spacing: 0

            ListView {
                id: winList
                Layout.fillWidth: true
                model: appGroup.modelData.windows
                spacing: Config.appearance.spacing.small
                boundsBehavior: Flickable.DragAndOvershootBounds
                implicitHeight: contentHeight + spacing
                reuseItems: true // ✅ enable reuse

                WheelHandler {
                    target: winList
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                }

                Behavior on implicitHeight {
                    Anim {}
                }

                // footer: StyledText {
                // anchors.right: parent.right
                // anchors.rightMargin: Config.appearance.spacing.small
                // text: `${appGroup.modelData.app_id} (${winList.count})`
                // font.pointSize: Config.appearance.font.size.extraSmall
                // color: Colours.palette.m3primary
                // }

                delegate: WindowItemDelegate {}
            }
        }
    }

    // -------- WindowItem --------------------------
    component WindowItemDelegate: StyledRect {
        id: itemMain

        required property var modelData

        implicitWidth: ListView.view.width
        implicitHeight: Config.bar.sizes.innerWidth
        radius: 0

        readonly property bool isFocused: Number(Niri.focusedWindowId) === Number(modelData.id)
        color: isFocused ? Colours.palette.m3primary : "transparent"

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Config.appearance.spacing.small
            spacing: Config.appearance.spacing.normal

            Loader {
                id: iconLoader
                Layout.alignment: Qt.AlignVCenter
                asynchronous: true
                sourceComponent: groupMenu.useImageIcon ? imageIconComp : materialIconComp
            }

            Component {
                id: materialIconComp
                MaterialIcon {
                    grade: 0
                    text: Icons.getAppCategoryIcon(itemMain.modelData?.app_id, "help_center")
                    font.pointSize: Config.appearance.font.size.large
                    color: itemMain.isFocused ? Colours.palette.m3onPrimary : groupMenu.onColor
                }
            }

            Component {
                id: imageIconComp
                IconImage {
                    source: Icons.getAppIcon(itemMain.modelData?.app_id || "", "image-missing")
                    implicitWidth: itemMain.isFocused ? Config.bar.sizes.innerWidth : Config.bar.sizes.innerWidth - 5
                    implicitHeight: implicitWidth
                }
            }

            StyledText {
                id: titleText
                Layout.fillWidth: true
                text: itemMain.modelData.title || itemMain.modelData.app_id || "Untitled"
                color: itemMain.isFocused ? Colours.palette.m3onPrimary : groupMenu.onColor
                elide: Text.ElideRight
            }
        }

        TapHandler {
            grabPermissions: PointerHandler.TakeOverForbidden
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onTapped: if (itemMain.modelData?.id)
                Niri.focusWindow(itemMain.modelData.id)
        }

        // ---- Pooling hooks ----
        ListView.onReused: {
            // reset properties that might linger
            color = Number(Niri.focusedWindowId) === Number(modelData.id) ? Colours.palette.m3primary : "transparent";
            titleText.text = modelData.title || modelData.app_id || "Untitled";
        }

        ListView.onPooled: {
            // optional: clear anything heavy
            // e.g., cancel animations, reset icon loader
            iconLoader.sourceComponent = null;
        }
    }
}
