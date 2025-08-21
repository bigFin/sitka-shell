import qs.components
import qs.services
import qs.config
import QtQuick

StyledRect {
    id: root
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter

    required property int groupOffset

    // Start hidden and below, animate in when loaded
    property bool entered: false

    color: Colours.palette.m3surfaceContainer
    radius: Appearance.rounding.large

    // Animate both y and opacity for a smooth effect
    anchors.topMargin: entered ? 0 : -Config.bar.sizes.innerHeight

    width: Config.bar.sizes.innerHeight + Appearance.spacing.small
    height: (text.contentHeight + Appearance.spacing.small)

    // Animate when 'entered' changes
    Behavior on anchors.topMargin {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    // Trigger animation when loaded
    Component.onCompleted: entered = true

    StyledText {
        id: text

        opacity: root.entered ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
        anchors.centerIn: parent

        font.family: Appearance.font.family.mono
        font.pointSize: Appearance.font.size.extraSmall

        color: Colours.palette.m3surfaceContainerHighest

        readonly property int pageNumber: Math.floor(root.groupOffset / Config.bar.workspaces.shown) + 1
        readonly property int totalPages: Math.ceil(Niri.getWorkspaceCount() / Config.bar.workspaces.shown)
        text: qsTr(`${pageNumber}/${totalPages}`)
    }
}
