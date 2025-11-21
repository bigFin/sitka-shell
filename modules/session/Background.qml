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
    
    // Enable left fillets only
    topLeftFillet: true
    topRightFillet: false
    bottomLeftFillet: true
    bottomRightFillet: false
    fillDisabledFillets: false
}