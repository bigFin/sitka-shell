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
    property bool contentVisible: false

    function showContent(): void {
        if (!utilitiesVisible)
            contentVisible = true
    }

    function hideContent(): void {
        contentVisible = false
    }

    Timer {
        id: hoverDelayTimer
        interval: 150
        repeat: false
        onTriggered: {
            if (!root.utilitiesVisible && root.isHovered)
                root.showContent()
        }
    }

    Timer {
        id: lingerTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (!root.isHovered)
                root.hideContent()
        }
    }

    onUtilitiesVisibleChanged: {
        if (utilitiesVisible) {
            hideContent()
            hoverDelayTimer.stop()
            lingerTimer.stop()
        }
    }

    Item {
        anchors.fill: parent

        transform: Translate {
            x: root.contentVisible ? 0 : root.implicitWidth
            y: root.contentVisible ? 0 : root.implicitHeight

            Behavior on x {
                NumberAnimation { duration: 150 }
            }
            Behavior on y {
                NumberAnimation { duration: 150 }
            }
        }

        opacity: root.contentVisible ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        // Chamfered triangle shape - bottom-right orientation
        Shape {
            id: cornerShape
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

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
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.contentVisible ? Qt.PointingHandCursor : Qt.ArrowCursor

        onEntered: {
            root.isHovered = true
            lingerTimer.stop()
            if (!root.utilitiesVisible && !root.contentVisible)
                hoverDelayTimer.start()
        }

        onExited: {
            root.isHovered = false
            hoverDelayTimer.stop()
            if (!root.utilitiesVisible && root.contentVisible)
                lingerTimer.restart()
        }

        onClicked: {
            if (root.contentVisible) {
                hoverDelayTimer.stop()
                lingerTimer.stop()
                root.hideContent()
                root.visibilities.utilities = true
            }
        }
    }
}
