import qs.components
import qs.services
import "../../../config"
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities

    implicitWidth: logo.implicitWidth + Config.appearance.padding.small * 2
    implicitHeight: logo.implicitHeight + Config.appearance.padding.small * 2

    StateLayer {
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: logo.implicitHeight + Config.appearance.padding.small * 2

        radius: Config.appearance.rounding.full

        function onClicked(): void {
            const newPinned = !visibilities.barPinned;
            visibilities.barPinned = newPinned;
            if (!newPinned)
                visibilities.bar = false;
        }
    }

    SystemLogo {
        id: logo

        anchors.centerIn: parent

        implicitWidth: Config.bar.sizes.innerWidth * 0.6
        implicitHeight: Config.bar.sizes.innerWidth * 0.6

        // Visual feedback for pinned state
        colorOverride: visibilities.barPinned ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        brightnessOverride: visibilities.barPinned ? 0.5 : 0.3
        
        // Subtle scale change when unpinned
        scale: visibilities.barPinned ? 1.0 : 0.85
        opacity: visibilities.barPinned ? 1.0 : 0.7
        
        Behavior on scale {
            NumberAnimation {
                duration: Config.appearance.anim.durations.small
                easing.bezierCurve: Config.appearance.anim.curves.standard
            }
        }
        
        Behavior on opacity {
            NumberAnimation {
                duration: Config.appearance.anim.durations.small
                easing.bezierCurve: Config.appearance.anim.curves.standard
            }
        }
    }
}
