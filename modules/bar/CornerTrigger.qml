pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.components.containers
import qs.components.effects
import qs.services
import "../../config"

// Corner trigger component - a chamfered corner hotspot that appears when bar is hidden
// Clicking it reveals the bar, which then overlays on top of windows

PanelWindow {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property bool barVisible

    // Configuration
    readonly property int triggerSize: Config.bar.cornerTrigger.size
    readonly property int hoverExpand: Config.bar.cornerTrigger.hoverExpand
    readonly property bool showLogo: Config.bar.cornerTrigger.showLogo
    readonly property real logoScale: Config.bar.cornerTrigger.logoScale

    // State
    property bool isHovered: false
    // Only active when mode is corner and bar is hidden
    readonly property bool triggerActive: Config.bar.revealMode === "corner" && !barVisible

    // Timer to keep trigger visible for a moment after bar closes
    Timer {
        id: lingerTimer
        interval: 3000
        repeat: false
    }

    onBarVisibleChanged: {
        if (!barVisible && Config.bar.revealMode === "corner") {
            lingerTimer.restart();
        }
    }

    // Window setup - overlay at bottom-left corner
    WlrLayershell.namespace: "corner-trigger"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.left: true
    anchors.bottom: true
    color: "transparent"

    // Size includes hover expansion
    readonly property int currentSize: triggerSize + (isHovered ? hoverExpand : 0)
    implicitWidth: currentSize
    implicitHeight: currentSize

    // Opacity logic:
    // - If bar is visible: 0 (and window hidden via state)
    // - If bar hidden:
    //   - Hovered: 1
    //   - Lingering after close: 1
    //   - Otherwise: 0 (but window stays visible to catch mouse)
    readonly property real targetOpacity: triggerActive ? (isHovered || lingerTimer.running ? 1.0 : 0.0) : 0.0

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Config.appearance.anim.durations.small
            easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Config.appearance.anim.durations.small
            easing.bezierCurve: Config.appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    // Content wrapper for opacity animation
    Item {
        id: content
        anchors.fill: parent
        opacity: 0 // Default for hidden state

        layer.enabled: true
        layer.effect: ShellShader {}

        // States for show/hide animation
        states: [
            State {
                name: "active"
                when: root.triggerActive
                PropertyChanges { target: root; visible: true }
                PropertyChanges { target: content; opacity: root.targetOpacity }
            },
            State {
                name: "inactive"
                when: !root.triggerActive
                PropertyChanges { target: root; visible: false }
                PropertyChanges { target: content; opacity: 0.0 }
            }
        ]

        transitions: [
            Transition {
                from: "inactive"
                to: "active"
                // When becoming active (bar closed), ensure visible immediately, then animate opacity if needed
                PropertyAction { target: root; property: "visible"; value: true }
            },
            Transition {
                from: "active"
                to: "inactive"
                // When becoming inactive (bar opened), hide immediately (or fade out?)
                // Usually we want it gone instantly so it doesn't overlap bar
                PropertyAction { target: root; property: "visible"; value: false }
            }
        ]
        
        // Smooth opacity transition for hover/linger
        Behavior on opacity {
            NumberAnimation {
                duration: Config.appearance.anim.durations.normal
                easing.bezierCurve: Config.appearance.anim.curves.standard
            }
        }

        // Chamfered triangle shape - bottom-left corner
        Shape {
            id: cornerShape
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: Colours.palette.m3surfaceContainer

                // Draw a chamfered triangle in bottom-left orientation
                // Start at top-left corner (0, 0)
                startX: 0
                startY: 0

                // Go to bottom-left corner
                PathLine { x: 0; y: root.currentSize }

                // Go to bottom-right corner
                PathLine { x: root.currentSize; y: root.currentSize }

                // Chamfer line back to start (creates the diagonal)
                PathLine { x: 0; y: 0 }
            }
        }

        // OS Logo centered in the triangle
        SystemLogo {
            id: logo
            visible: root.showLogo

            // Position in the center-ish of the triangle (weighted toward bottom-left)
            x: root.currentSize * 0.25 - width / 2
            y: root.currentSize * 0.65 - height / 2

            implicitWidth: root.triggerSize * root.logoScale
            implicitHeight: root.triggerSize * root.logoScale

            colorOverride: root.isHovered ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            brightnessOverride: root.isHovered ? 0.6 : 0.4

            Behavior on colorOverride {
                ColorAnimation {
                    duration: Config.appearance.anim.durations.small
                }
            }
        }

        // Mouse interaction
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: {
                root.isHovered = true;
            }

            onExited: {
                root.isHovered = false;
            }

            onClicked: {
                // Toggle bar visibility (pin it open)
                root.visibilities.barPinned = true;
            }
        }
    }
}
