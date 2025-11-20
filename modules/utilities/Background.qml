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
    filletStyle: 1 // Chamfer
    
    // Enable fillets for corners facing the screen (assuming right anchor)
    topLeftFillet: true
    topRightFillet: false
    bottomLeftFillet: true
    bottomRightFillet: false
}