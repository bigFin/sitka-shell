import qs.components
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    anchors.fill: parent
    anchors.margins: Appearance.padding.large

    spacing: Appearance.spacing.smaller

    StyledText {
        Layout.fillWidth: true
        text: qsTr("%1 notification%2").arg(Notifs.list.length || "No").arg(Notifs.list.length === 1 ? "" : "s")
        color: Colours.palette.m3outline
        elide: Text.ElideRight
    }

    ClippingRectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: Appearance.rounding.small
        color: "transparent"

        StyledListView {
            anchors.fill: parent

            spacing: Appearance.spacing.small
            clip: true

            model: ScriptModel {
                values: [...new Set(Notifs.list.map(notif => notif.appName))].reverse()
            }

            delegate: NotifGroup {}

            add: Transition {
                Anim {
                    property: "opacity"
                    from: 0
                    to: 1
                }
                Anim {
                    property: "scale"
                    from: 0
                    to: 1
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            move: Transition {
                Anim {
                    property: "y"
                }
            }

            displaced: Transition {
                Anim {
                    property: "y"
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
