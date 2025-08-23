pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import qs.components.effects

Item {
    id: root

    required property int groupOffset
    required property int wsOffset

    readonly property Item anchorWs: Niri.wsAnchorItem
    readonly property int rounding: Appearance.padding.normal
    readonly property int roundedSize: Config.bar.workspaces.rounded ? rounding : 0

    component HighlightRect: StyledRect {
        id: hrect

        property color highlightColor: Colours.palette.m3surfaceContainer
        property int yOffset: -Appearance.padding.small / 2
        property int extraHeight: 0
        property int zOrder: 0
        property int cornerPieceSize: Config.bar.sizes.innerWidth + Appearance.padding.small

        readonly property Item ws: root.anchorWs

        z: zOrder
        color: highlightColor

        topLeftRadius: root.roundedSize
        bottomLeftRadius: root.roundedSize

        Corner {
            cornerType: 3
        } // top
        Corner {
            cornerType: 1
        } // bottom

        x: 0
        y: ws.mapToItem(root, 0, 0).y + yOffset

        implicitWidth: ws ? Config.bar.sizes.innerWidth + Appearance.padding.normal : 0
        implicitHeight: (ws?.height ?? Config.bar.sizes.innerWidth) + extraHeight + Appearance.padding.small

        Behavior on implicitWidth {
            Anim {}
        }
        Behavior on implicitHeight {
            Anim {}
        }
        Behavior on x {
            Anim {}
        }
        Behavior on y {
            // enabled: hrect.ws === null
            Anim {}
        }
    }

    // Instances
    HighlightRect {
        id: highlight
        highlightColor: Colours.palette.m3background
        anchors.right: parent.left
        zOrder: 2
    }

    HighlightRect {
        id: highlightLow
        highlightColor: Colours.palette.m3surfaceContainer
        anchors.verticalCenter: highlight.verticalCenter
        anchors.left: highlight.left
        anchors.leftMargin: -Appearance.padding.small

        implicitHeight: (ws?.height ?? Config.bar.sizes.innerWidth) + extraHeight + Appearance.padding.small + Appearance.padding.small * 2
        zOrder: 1

        // topRightRadius: Config.bar.workspaces.rounded ? Appearance.padding.small : 0
        // bottomRightRadius: Config.bar.workspaces.rounded ? Appearance.padding.small : 0
    }

    Rectangle {
        width: Appearance.padding.small
        height: highlightLow.implicitHeight + highlightLow.cornerPieceSize + Appearance.padding.normal

        anchors.verticalCenter: highlightLow.verticalCenter
        anchors.left: highlightLow.right

        visible: highlight.width > 0

        color: Colours.palette.m3surfaceContainer
    }

    // Corner sub-component
    component Corner: CornerPiece {
        property int cornerType: 0 // 1 = bottom, 3 = top
        width: parent.ws ? parent.cornerPieceSize : 0
        height: parent.cornerPieceSize / 2
        radius: root.rounding * 2
        orientation: cornerType
        color: parent.highlightColor

        anchors.right: parent.right
        anchors.rightMargin: -1
        anchors.top: cornerType === 1 ? parent.bottom : undefined
        anchors.bottom: cornerType === 3 ? parent.top : undefined
        anchors.topMargin: cornerType === 1 ? -1 : undefined
        anchors.bottomMargin: cornerType === 3 ? -1 : undefined

        Behavior on width {
            Anim {}
        }
        Behavior on radius {
            Anim {}
        }
    }

    // Reusable animation
    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
