pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import "../../../../../config"
import qs.components

Item {
    id: root
    required property Item iconObj

    readonly property var fokus: ({
            workspace: iconObj.isWsFocused,
            icon: iconObj.isFocused,
            get true(){
                return this.workspace && this.icon;
            }
        })
    readonly property bool popupActive: iconObj.popupActive
    readonly property bool isWorkspace: ["workspace", "workspaces"].includes(WMService.wsContextType)
    readonly property int windowCount: iconObj.windowCount

    readonly property var windows: root.isWorkspace ? [root.iconObj.groupWindowData[0]] : root.iconObj.groupWindowData
    readonly property var mainWindow: root.iconObj.windowData
    readonly property bool multiWindow: windowCount > 1 && !isWorkspace

    readonly property int itemH: iconObj.height

    property bool activated: false
    Component.onCompleted: activated = true

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    // opacity: popupActive && activated ? 1 : 0

    // height: popupActive && activated && (Niri.wsContextAnchor) ? contextLoader.height : parent.height
    // width: popupActive && activated && (Niri.wsContextAnchor) ? contextLoader.width : parent.width

    // clip: true

    Behavior on width {
        Anim {
            easing.bezierCurve: Config.appearance.anim.curves.emphasized
        }
    }

    // Component wrappers
    Component {
        id: singleComp

        ItemWorkspaceContext {
            onPrimary: root.fokus.workspace
            isFocused: root.fokus.true
            itemH: root.itemH

            mainWindow: root.mainWindow

            displayTitle: WMService.cleanWindowTitle(root.mainWindow.title || "Untitled")
            displaySubtitle: (root.mainWindow.app_id || "Untitled")  /* + (root.windowCount > 1 ? " (" + root.windowCount + " windows)" : "") */

            // activated: root.activated
            popupActive: root.popupActive
        }
    }

    Component {
        id: multiComp
        MultiWindowContext {
            windows: root.windows
            fokus: root.fokus
            itemH: root.itemH
            // activated: root.activated
            popupActive: root.popupActive
        }
    }

    Loader {
        id: contextLoader

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        active: root.popupActive && root.activated
        // active: root.activated && !(WMService.wsContextType === "none") && root.popupActive

        sourceComponent: root.multiWindow ? multiComp : singleComp
    }
}
