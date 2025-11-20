import qs.components
import qs.components.misc
import qs.services
import "../../../config"
import QtQuick

Row {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    padding: Config.appearance.padding.large
    spacing: Config.appearance.spacing.normal

    Ref {
        service: SystemUsage
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

            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
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
