import qs.components
import qs.services
import "../../config"
import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property Item bar

    anchors.fill: parent

    StyledRect {
        anchors.fill: parent
        color: Colours.palette.m3surface
        
        // Apply large fillets for primary elements
        filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6

        layer.enabled: true
        layer.effect: MultiEffect {
            maskSource: mask
            maskEnabled: true
            maskInverted: true
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        StyledRect {
            anchors.fill: parent
            anchors.margins: Config.border.thickness
            anchors.leftMargin: root.bar.implicitWidth
            
            color: "black"
            
            // Match fillet size for inner mask (maybe slightly smaller?)
            // Using same size for now
            filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6
        }
    }
}