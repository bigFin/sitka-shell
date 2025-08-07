pragma Singleton

import qs.services
import qs.config
import Quickshell
import QtQuick

Singleton {
    id: root

    function create(parent: Item, props: var): void {
        controlCenter.createObject(parent ?? dummy, props);
    }

    QtObject {
        id: dummy
    }

    Component {
        id: controlCenter

        FloatingWindow {
            id: win

            property alias active: cc.active
            property alias navExpanded: cc.navExpanded

            color: Colours.palette.m3surface

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            minimumSize.width: 1000
            minimumSize.height: 600

            implicitWidth: cc.implicitWidth
            implicitHeight: cc.implicitHeight

            ControlCenter {
                id: cc

                anchors.fill: parent
                screen: win.screen
                floating: true

                function close(): void {
                    win.visible = false;
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.standard
                }
            }
        }
    }
}
