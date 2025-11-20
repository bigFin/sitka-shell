import qs.components
import qs.services
import "../../../config"
import Quickshell.Services.SystemTray
import QtQuick

StyledRect {
    id: root

    readonly property alias items: items

    clip: true
    visible: width > 0 && height > 0 // To avoid warnings about being visible with no size

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: layout.implicitHeight + (Config.bar.tray.background ? Config.appearance.padding.normal : Config.appearance.padding.small) * 2

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.tray.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Config.appearance.rounding.full

    Column {
        id: layout

        anchors.centerIn: parent
        spacing: Config.appearance.spacing.small

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing.bezierCurve: Config.appearance.anim.curves.standardDecel
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing.bezierCurve: Config.appearance.anim.curves.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        Repeater {
            id: items

            model: SystemTray.items
            TrayItem {}
        }
    }

    Behavior on implicitWidth {
        Anim {
            easing.bezierCurve: Config.appearance.anim.curves.emphasized
        }
    }

    Behavior on implicitHeight {
        Anim {
            easing.bezierCurve: Config.appearance.anim.curves.emphasized
        }
    }
}
