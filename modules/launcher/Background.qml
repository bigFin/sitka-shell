import qs.components
import qs.services
import "../../config"
import QtQuick

StyledRect {
    id: root

    required property Wrapper wrapper
    
    color: Colours.palette.m3surface
    
    // Apply large fillets for main containers
    filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6
    
    // Enable top fillets only
    topLeftFillet: true
    topRightFillet: true
    bottomLeftFillet: false
    bottomRightFillet: false
}