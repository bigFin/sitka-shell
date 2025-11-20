import qs.components
import qs.services
import "../../../config"
import QtQuick

StyledRect {
    id: root

    required property Wrapper wrapper
    required property bool invertBottomRounding // Ignored for chamfers
    
    color: Colours.palette.m3surface
    
    // Apply large fillets for main containers
    filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6
    
    readonly property bool attached: !wrapper.isDetached
    
    // If detached, round all. If attached (to left bar), round right side.
    topLeftFillet: !attached
    topRightFillet: true
    bottomLeftFillet: !attached
    bottomRightFillet: true
}