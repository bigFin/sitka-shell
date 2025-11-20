import qs.components
import qs.services
import "../../config"
import QtQuick

StyledRect {
    id: root

    required property Wrapper wrapper
    
    // Match the original background properties
    color: Colours.palette.m3surface
    
    // Apply large fillets for main containers
    filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.large : 6
    
    // Animation inherited from StyledRect
}