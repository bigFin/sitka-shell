import qs.components
import qs.services
import "../../../../config"
import QtQuick

StyledRect {
    id: root
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter

    required property int groupOffset

    Component.onCompleted: active = true
    property bool active: false
    property bool entered: Config.bar.workspaces.shown < Niri.getWorkspaceCount() && active

    color: Colours.palette.m3surfaceContainer
    radius: 0
    
    // Apply small fillets for tertiary elements
    filletSize: Config.appearance && Config.appearance.fillet ? Config.appearance.fillet.small : 2

    // Animate both y and opacity for a smooth effect
    anchors.topMargin: entered ? -Config.appearance.padding.normal : -Config.bar.sizes.innerWidth

    width: Config.bar.sizes.innerWidth - Config.appearance.spacing.small
    height: (text.contentHeight + Config.appearance.spacing.normal)

    // Animate when 'entered' changes
    Behavior on anchors.topMargin {
        Anim {}
    }

    StyledText {
        id: text

        opacity: root.entered ? 1 : 0
        Behavior on opacity {
            Anim {}
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Config.appearance.spacing.small / 2

        font.family: Config.appearance.font.family.mono
        font.pointSize: Config.appearance.font.size.extraSmall

        color: Colours.palette.m3surfaceContainerHighest

        readonly property int pageNumber: Math.floor(root.groupOffset / Config.bar.workspaces.shown) + 1
        readonly property int totalPages: Math.ceil(Niri.getWorkspaceCount() / Config.bar.workspaces.shown)
        text: qsTr(`${pageNumber}/${totalPages}`)
    }
}
