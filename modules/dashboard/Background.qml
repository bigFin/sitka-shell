import qs.components
import qs.services
import qs.config
import QtQuick

StyledRect {
    id: root

    required property Wrapper wrapper
    
    // Match the original background properties
    color: Colours.palette.m3surface
    
    // Apply large fillets for main containers
    filletSize: Appearance.fillet.large
    
    // Animation inherited from StyledRect
}