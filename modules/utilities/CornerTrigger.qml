pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services
import "../../config"

// Bottom-right corner trigger for utilities panel
PanelWindow {
    id: root

    required property ShellScreen targetScreen
    required property PersistentProperties visibilities

    screen: targetScreen

    readonly property int triggerSize: 48
    readonly property bool utilitiesVisible: visibilities.utilities

    // Window setup - overlay at bottom-right corner
    WlrLayershell.namespace: "utilities-corner-trigger"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.right: true
    anchors.bottom: true
    color: "transparent"

    visible: !utilitiesVisible
    implicitWidth: triggerSize
    implicitHeight: triggerSize

    property bool isHovered: false

    // Chamfered triangle shape - bottom-right orientation
    Shape {
        id: cornerShape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        opacity: root.isHovered ? 1 : 0.6

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: Colours.palette.m3surfaceContainer

            // Draw triangle in bottom-right
            startX: root.triggerSize
            startY: 0
            PathLine { x: root.triggerSize; y: root.triggerSize }
            PathLine { x: 0; y: root.triggerSize }
            PathLine { x: root.triggerSize; y: 0 }
        }
    }

    // Icon
    MaterialIcon {
        x: root.triggerSize * 0.55
        y: root.triggerSize * 0.55
        text: "tune"
        color: root.isHovered ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        font.pointSize: Config.appearance.font.size.normal

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.isHovered = true
        onExited: root.isHovered = false

        onClicked: {
            root.visibilities.utilities = true
        }
    }
}
