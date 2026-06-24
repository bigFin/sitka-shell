import qs.components
import qs.components.misc
import qs.services
import "../../../config"
import QtQuick

Row {
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
        icon: "memory"
        value: SystemUsage.cpuPerc
        colour: Colours.palette.m3primary
    }

    Resource {
        icon: "memory_alt"
        value: SystemUsage.memPerc
        colour: Colours.palette.m3secondary
    }

    Resource {
        icon: "hard_disk"
        value: SystemUsage.storagePerc
        colour: Colours.palette.m3tertiary
    }

    component Resource: Item {
        id: res

        required property string icon
        required property real value
        required property color colour

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Config.appearance.padding.large
        implicitWidth: icon.implicitWidth

        StyledRect {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: icon.top
            anchors.bottomMargin: Config.appearance.spacing.small

            implicitWidth: Config.dashboard.sizes.resourceProgessThickness

            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Config.appearance.rounding.full

            StyledRect {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                implicitHeight: res.value * parent.height

                color: res.colour
                radius: Config.appearance.rounding.full
            }
        }

        MaterialIcon {
            id: icon

            anchors.bottom: parent.bottom

            text: res.icon
            color: res.colour
        }

        Behavior on value {
            Anim {
                duration: Config.appearance.anim.durations.large
            }
        }
    }
}
