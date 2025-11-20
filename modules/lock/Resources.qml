import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import "../../config"
import QtQuick
import QtQuick.Layouts

GridLayout {
    id: root

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Config.appearance.padding.large

    rowSpacing: Config.appearance.spacing.large
    columnSpacing: Config.appearance.spacing.large
    rows: 2
    columns: 2

    Ref {
        service: SystemUsage
    }

    Resource {
        Layout.topMargin: Config.appearance.padding.large
        icon: "memory"
        value: SystemUsage.cpuPerc
        colour: Colours.palette.m3primary
    }

    Resource {
        Layout.topMargin: Config.appearance.padding.large
        icon: "thermostat"
        value: Math.min(1, SystemUsage.cpuTemp / 90)
        colour: Colours.palette.m3secondary
    }

    Resource {
        Layout.bottomMargin: Config.appearance.padding.large
        icon: "memory_alt"
        value: SystemUsage.memPerc
        colour: Colours.palette.m3secondary
    }

    Resource {
        Layout.bottomMargin: Config.appearance.padding.large
        icon: "hard_disk"
        value: SystemUsage.storagePerc
        colour: Colours.palette.m3tertiary
    }

    component Resource: StyledRect {
        id: res

        required property string icon
        required property real value
        required property color colour

        Layout.fillWidth: true
        implicitHeight: width

        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
        radius: Config.appearance.rounding.large

        CircularProgress {
            id: circ

            anchors.fill: parent
            value: res.value
            padding: Config.appearance.padding.large * 3
            fgColour: res.colour
            bgColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 3)
            strokeWidth: width < 200 ? Config.appearance.padding.smaller : Config.appearance.padding.normal
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            text: res.icon
            color: res.colour
            font.pointSize: (circ.arcRadius * 0.7) || 1
            font.weight: 600
        }

        Behavior on value {
            Anim {
                duration: Config.appearance.anim.durations.large
            }
        }
    }
}
