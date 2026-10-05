import qs.components
import qs.services
import "../../../config"
import QtQuick
import "../../../utils/scripts/dashboardData.js" as DashboardData

Column {
    id: root

    property bool active: true
    property bool _systemUsageRefHeld: false
    readonly property var systemUsageDomains: ["cpu", "memory", "storage"]

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    padding: Config.appearance.padding.large
    spacing: Config.appearance.spacing.normal

    Component.onCompleted: updateSystemUsageRef()
    Component.onDestruction: releaseSystemUsageRef()
    onActiveChanged: updateSystemUsageRef()

    function updateSystemUsageRef(): void {
        if (active && !_systemUsageRefHeld) {
            SystemUsage.addRef(systemUsageDomains);
            _systemUsageRefHeld = true;
        } else if (!active && _systemUsageRefHeld) {
            releaseSystemUsageRef();
        }
    }

    function releaseSystemUsageRef(): void {
        if (!_systemUsageRefHeld)
            return;
        SystemUsage.removeRef(systemUsageDomains);
        _systemUsageRefHeld = false;
    }

    Resource {
        label: qsTr("CPU")
        reading: DashboardData.percent(SystemUsage.cpuPerc, SystemUsage.cpuState)
    }

    Resource {
        label: qsTr("Memory")
        reading: DashboardData.percent(SystemUsage.memPerc, SystemUsage.memoryState)
    }

    Resource {
        label: qsTr("Storage")
        reading: DashboardData.percent(SystemUsage.storagePerc, SystemUsage.storageState)
    }

    Resource {
        label: qsTr("Audio")
        reading: !Audio.sink?.ready || !Audio.sink?.audio ? "—" : Audio.muted ? qsTr("Muted") : Math.round(Audio.volume * 100) + "%"
    }

    component Resource: StyledText {
        required property string label
        required property string reading
        width: Config.dashboard.sizes.resourceSize - root.padding * 2
        fontSizeMode: Text.HorizontalFit
        minimumPointSize: Config.appearance.font.size.small
        elide: Text.ElideRight
        text: label + "  " + reading
        color: Colours.palette.m3onSurface
    }
}
