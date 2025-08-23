pragma ComponentBehavior: Bound

import qs.services
import qs.utils
import qs.config
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.components.containers

RowLayout {
    id: root

    // Centralized constants to avoid repeating expressions
    readonly property real itemH: Config.launcher.sizes.itemHeight / 2
    readonly property real iconSize: Config.bar.sizes.innerWidth
    readonly property real expandedW: 550
    readonly property real spacingNormal: Appearance.spacing.normal

    anchors.left: parent.left
    anchors.leftMargin: -spacingNormal

    StyledListView {
        id: windowList

        readonly property var windows: Niri.wsItemWindows ?? []
        readonly property bool useImageIcon: Config.bar.workspaces.windowIconImage

        onWindowsChanged: {
            windowList.implicitHeight = root.itemH;
        }

        readonly property color bgColor: Colours.palette.m3surfaceContainer
        readonly property color onColor: Colours.palette.m3onSurfaceVariant

        readonly property int widt: Math.min(root.expandedW, currentItem.width) + root.spacingNormal

        Layout.fillWidth: true
        implicitHeight: root.itemH
        implicitWidth: windows.length > 1 ? widt + idxCounter.width : widt

        visible: windows.length > 0
        spacing: root.spacingNormal
        reuseItems: true
        orientation: Qt.Vertical
        boundsBehavior: Flickable.DragAndOvershootBounds
        maximumFlickVelocity: 500
        model: windows

        WheelHandler {
            target: windowList
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                if (!event)
                    return;
                event.angleDelta.y < 0 ? windowList.incrementCurrentIndex() : windowList.decrementCurrentIndex();
                event.accepted = true;
            }
        }

        populate: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.anim.durations.normal
            }
        }
        remove: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Appearance.anim.durations.normal
            }
        }

        delegate: WindowItemDelegate {}
    }

    // Show index counter only if multiple windows
    Loader {
        id: idxCounter
        active: windowList.windows.length > 1

        sourceComponent: StyledRect {
            radius: Appearance.rounding.small
            implicitWidth: tex.contentWidth + root.spacingNormal
            implicitHeight: root.itemH
            color: Colours.palette.m3tertiary

            StyledText {
                id: tex
                anchors.centerIn: parent
                text: `${windowList.currentIndex + 1}/${windowList.windows.length}`
                font.pointSize: Appearance.font.size.large
                font.family: Appearance.font.family.mono
                color: Colours.palette.m3onTertiary
            }

            TapHandler {

                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onTapped: {
                    const expandH = windowList.windows.length * (root.itemH + windowList.spacing) - windowList.spacing;
                    if (windowList.implicitHeight !== expandH) {
                        windowList.implicitHeight = expandH;
                    } else {
                        windowList.implicitHeight = root.itemH;
                    }
                }
            }
        }
    }

    // -------- Components --------------------------

    component WindowItemDelegate: StyledRect {
        id: wd
        required property var modelData
        required property int index
        readonly property bool isFocused: Number(Niri.focusedWindowId) === Number(modelData?.id)

        readonly property int wid: Math.min(root.expandedW, title.implicitWidth /* + iconLoader.implicitWidth */ ) + root.spacingNormal

        implicitHeight: root.itemH
        // implicitWidth: windowList.windows.length > 1 ? root.expandedW : wid
        implicitWidth: wid

        radius: Appearance.rounding.small / 2
        color: "transparent"

        RowLayout {
            spacing: root.spacingNormal
            anchors.verticalCenter: parent.verticalCenter

            // Loader {
            //     id: iconLoader
            //     asynchronous: true
            //     sourceComponent: windowList.useImageIcon ? imageIconComp : materialIconComp
            // }

            Component {
                id: materialIconComp
                MaterialIcon {
                    grade: 0
                    text: Icons.getAppCategoryIcon(wd.modelData?.app_id, "help_center")
                    font.pointSize: root.iconSize * 1.3
                    color: wd.isFocused ? Colours.palette.m3primary : windowList.onColor
                }
            }

            Component {
                id: imageIconComp
                IconImage {
                    source: Icons.getAppIcon(wd.modelData?.app_id || "", "image-missing")
                    implicitWidth: root.iconSize
                    implicitHeight: root.iconSize
                }
            }

            ColumnLayout {
                id: title
                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    text: wd.modelData?.title || wd.modelData?.app_id || "Untitled"
                    font.pointSize: Appearance.font.size.small
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                    maximumLineCount: 1
                    color: wd.isFocused ? Colours.palette.m3primary : windowList.onColor
                    Layout.preferredWidth: contentWidth
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: windowList.windows[0]?.app_id || ""
                    font.pointSize: Appearance.font.size.extraSmall
                    font.family: Appearance.font.family.mono
                    elide: Text.ElideRight
                    color: wd.isFocused ? Colours.palette.m3primary : Colours.palette.m3tertiary
                }
            }
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onTapped: if (Niri.focusWindow && wd.modelData?.id)
                Niri.focusWindow(wd.modelData.id)
        }

        // Pooling hooks
        ListView.onReused: color = isFocused ? Colours.palette.m3primary : "transparent"
        ListView.onPooled: iconLoader.sourceComponent = null
    }
}
