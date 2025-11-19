import qs.components
import qs.services
import qs.config
import QtQuick

StyledRect {
    id: root

    required property Wrapper wrapper
    
    color: Colours.palette.m3surface
    
    // Apply large fillets for main containers
    filletSize: Appearance.fillet.large
    
    // Enable top-left fillet only
    topLeftFillet: true
    topRightFillet: false
    bottomLeftFillet: false
    bottomRightFillet: false
}