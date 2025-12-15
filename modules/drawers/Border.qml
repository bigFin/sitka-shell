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
        
        // Use transparent fill + border width instead of masking
        color: "transparent"
        border.color: Colours.palette.m3surface
        border.width: Config.border.thickness
        
        // Disable custom fillet shape to use standard Rectangle with border support
        enableFillets: false
        
        property int fSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6
        
        // Top corners: Sharp/Square
        topLeftRadius: 0
        topRightRadius: 0
        
        // Bottom corners: Rounded (Fillet size)
        bottomLeftRadius: fSize
        bottomRightRadius: fSize
        
        // Remove layer masking which fails inside ShaderEffectSource
        layer.enabled: false
    }
}
