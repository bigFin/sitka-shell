pragma ComponentBehavior: Bound

import qs.services
import "../../../config"
import QtQuick

Item {
    id: root

    // Constants
    readonly property Item anchorWs: WMService.wsContextAnchor
    readonly property int anchorWsCount: WMService.wsContextType === "workspace" || WMService.wsContextType === "workspaces" ? 1 : WMService.wsContextAnchor?.windowCount
    readonly property real itemH: (anchorWs ? anchorWs.height : 0) + Config.bar.workspaces.windowIconGap * 2
    readonly property real expandedW: Config.bar.workspaces.windowIconContextWidth - Config.bar.workspaces.windowIconSize

    implicitHeight: anchorWs ? ((itemH + Config.appearance.padding.small) * anchorWsCount) : itemH - Config.appearance.padding.normal
    implicitWidth: root.expandedW
}
