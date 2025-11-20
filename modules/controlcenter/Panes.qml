import "bluetooth"
import qs.components
import qs.services
import "../../config"
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

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

    ColumnLayout {
        id: layout

        spacing: 0
        y: -root.session.activeIndex * root.height
        width: parent.width
        // Height matches content

        Pane {
            index: 0
            sourceComponent: Item {
                StyledText {
                    anchors.centerIn: parent
                    text: qsTr("Work in progress")
                    color: Colours.palette.m3outline
                    font.pointSize: Config.appearance.font.size.extraLarge
                    font.weight: 500
                }
            }
        }

        Pane {
            index: 1
            sourceComponent: BtPane {
                session: root.session
            }
        }

        Pane {
            index: 2
            sourceComponent: Item {
                StyledText {
                    anchors.centerIn: parent
                    text: qsTr("Work in progress")
                    color: Colours.palette.m3outline
                    font.pointSize: Config.appearance.font.size.extraLarge
                    font.weight: 500
                }
            }
        }

        Behavior on y {
            Anim {}
        }
        
        layer.enabled: true
        layer.effect: MultiEffect {
            maskSource: mask
            maskEnabled: true
            maskInverted: false
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }

    component Pane: Item {
        id: pane

        required property int index
        property alias sourceComponent: loader.sourceComponent

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