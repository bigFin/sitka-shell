pragma ComponentBehavior: Bound

import ".."
import qs.services
import "../../config"
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

// Shared silhouette for the two drawers that dock against a horizontal edge.
StyledRect {
    id: root

    required property bool dockAtTop
    property bool topButtressesVisible: false
    readonly property real lipY: dockAtTop ? height - 1.5 : 1.5
    readonly property real shoulder: Math.max(2, effectiveFilletSize)
    readonly property bool ceramic: Colours.themeName === "SunWorkstation"
    readonly property bool trimVisible: ceramic && visible && width >= 100 && height >= 20

    color: Colours.tPalette.m3surface
    ditherRelief: ceramic ? (dockAtTop ? -1 : 1) : 0
    filletSize: Config.appearance.fillet.large
    topLeftFillet: !dockAtTop || !topButtressesVisible
    topRightFillet: topLeftFillet
    topLeftFilletStyle: 1
    topRightFilletStyle: 1
    bottomLeftFillet: dockAtTop
    bottomRightFillet: dockAtTop
    bottomLeftFilletStyle: 1
    bottomRightFilletStyle: 1

    // Keep the shadow behind the fill, and never capture the drawer contents
    // into an offscreen texture. Closed drawers and other themes pay no cost.
    Loader {
        anchors.fill: parent
        anchors.margins: 2
        z: -1
        active: root.trimVisible

        sourceComponent: RectangularShadow {
            radius: root.shoulder
            color: Qt.alpha(Colours.palette.m3shadow, 0.55)
            blur: 15
            spread: 3
            offset.y: root.dockAtTop ? 5 : -5
        }
    }

    Loader {
        anchors.fill: parent
        z: 1
        active: root.trimVisible

        sourceComponent: Shape {
            id: lip

            readonly property real elbowY: root.lipY + (root.dockAtTop ? -root.shoulder : root.shoulder)
            readonly property real insetY: root.lipY + (root.dockAtTop ? -2 : 2)

            ShapePath {
                fillColor: "transparent"
                strokeColor: Colours.palette.m3surfaceBright
                strokeWidth: 1
                startX: root.shoulder + 2
                startY: lip.insetY
                PathLine { x: root.width - root.shoulder - 2; y: lip.insetY }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(Colours.palette.m3outline, 0.74)
                strokeWidth: 1
                capStyle: ShapePath.FlatCap
                startX: 1.5
                startY: lip.elbowY
                PathLine { x: root.shoulder + 1; y: root.lipY }
                PathLine { x: root.width - root.shoulder - 1; y: root.lipY }
                PathLine { x: root.width - 1.5; y: lip.elbowY }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: Colours.palette.m3primary
                strokeWidth: 2
                capStyle: ShapePath.FlatCap
                startX: root.shoulder + 11
                startY: root.lipY
                PathLine { x: root.shoulder + 35; y: root.lipY }
            }
        }
    }
}
