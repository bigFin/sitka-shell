import "bluetooth"
import qs.components
import qs.components.containers
import qs.services
import "../../config"
import qs.utils
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Sitka

Item {
    id: root

    required property Session session
    
    // Mimic ClippingRectangle properties used by ControlCenter.qml
    property alias topRightRadius: mask.radius // Dummy for compatibility
    property alias bottomRightRadius: mask.radius // Dummy
    
    // Actually control fillets
    property bool topRightFillet: true
    property bool bottomRightFillet: true
    
    StyledRect {
        id: mask
        anchors.fill: parent
        visible: false
        color: "black"
        filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6
        
        // Logic: if radius (from parent binding) is > 0, enable fillets.
        property bool effectiveEnabled: radius > 0
        
        topLeftFillet: false
        bottomLeftFillet: false
        topRightFillet: effectiveEnabled
        bottomRightFillet: effectiveEnabled
    }

    Item {
        id: viewport
        anchors.fill: parent
        
        // layer.enabled: true
        layer.effect: MultiEffect {
            maskSource: mask
            maskEnabled: true
            maskInverted: false
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        ColumnLayout {
            id: layout

            spacing: 0
            y: -root.session.activeIndex * root.height
            width: parent.width
            // Height matches content

            Pane {
                index: 0
                sourceComponent: BtPane {
                    session: root.session
                }
            }

            Pane {
                index: 1
                source: "BackgroundPane.qml"
            }

            Behavior on y {
                Anim {}
            }
        }
    }

    component Pane: Item {
        id: pane

        required property int index
        property alias sourceComponent: loader.sourceComponent
        property alias source: loader.source

        implicitWidth: root.width
        implicitHeight: root.height

        Loader {
            id: loader

            anchors.fill: parent
            clip: true
            asynchronous: true
            active: {
                if (root.session.activeIndex === pane.index)
                    return true;

                const ly = -layout.y;
                const ty = pane.index * root.height;
                return ly + root.height > ty && ly < ty + root.height;
            }
        }
    }
}