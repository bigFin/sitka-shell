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
    readonly property bool showLogo: Config.bar.cornerTrigger.showLogo
    readonly property real logoScale: Config.bar.cornerTrigger.logoScale

    // State properties
    property bool isHovered: false
    property bool introComplete: false
    property bool contentVisible: false  // Whether content should be visible (slid in)
    property bool dismissed: false       // True after click - prevents re-showing until bar hides again

    // Only active when mode is corner and bar is hidden
    readonly property bool triggerActive: Config.bar.revealMode === "corner" && !barVisible

    // Window setup - overlay at bottom-left corner
    WlrLayershell.namespace: "corner-trigger"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.left: true
    anchors.bottom: true
    color: "transparent"

    // Window is visible whenever corner mode is active - it's a transparent hover zone
    // The content inside slides in/out
    visible: triggerActive

    implicitWidth: triggerSize
    implicitHeight: triggerSize

    // Timers
    Timer {
        id: introDelayTimer
        interval: 500
        repeat: false
        onTriggered: {
            root.contentVisible = true
            introPauseTimer.start()
        }
    }

    Timer {
        id: introPauseTimer
        interval: 1000  // Show for 1 second during intro
        repeat: false
        onTriggered: {
            root.contentVisible = false
            root.introComplete = true
        }
    }

    Timer {
        id: hoverDelayTimer
        interval: 150
        repeat: false
        onTriggered: {
            root.contentVisible = true
        }
    }

    Timer {
        id: lingerTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (!root.isHovered) {
                root.contentVisible = false
            }
        }
    }

    Component.onCompleted: {
        if (triggerActive) {
            introDelayTimer.start()
        }
    }

    onTriggerActiveChanged: {
        if (triggerActive && !introComplete) {
            // Start intro if not done yet
            introDelayTimer.start()
        } else if (triggerActive && introComplete) {
            // Bar just became hidden again - reset dismissed flag so hover works
            root.dismissed = false
        } else if (!triggerActive) {
            // Bar became visible, hide content immediately
            root.contentVisible = false
            // Stop any running timers
            introDelayTimer.stop()
            introPauseTimer.stop()
            hoverDelayTimer.stop()
            lingerTimer.stop()
        }
    }

    // Content wrapper
    Item {
        id: content
        anchors.fill: parent

        // Slide transform - start off-screen (bottom-left)
        transform: Translate {
            id: slideTransform
            x: root.contentVisible ? 0 : -root.implicitWidth
            y: root.contentVisible ? 0 : root.implicitHeight

            Behavior on x {
                enabled: !root.dismissed  // Disable animation when dismissed
                NumberAnimation {
                    duration: Config.appearance.anim.durations.small
                    easing.bezierCurve: Config.appearance.anim.curves.expressiveFastSpatial
                }
            }

            Behavior on y {
                enabled: !root.dismissed  // Disable animation when dismissed
                NumberAnimation {
                    duration: Config.appearance.anim.durations.small
                    easing.bezierCurve: Config.appearance.anim.curves.expressiveFastSpatial
                }
            }
        }

        // Content opacity for smooth fade
        opacity: root.contentVisible ? 1 : 0

        Behavior on opacity {
            enabled: !root.dismissed  // Disable animation when dismissed
            NumberAnimation {
                duration: Config.appearance.anim.durations.small
                easing.bezierCurve: Config.appearance.anim.curves.standard
            }
        }

        layer.enabled: true
        layer.effect: ShellShader {}

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
                startX: 0
                startY: 0
                PathLine { x: 0; y: root.triggerSize }
                PathLine { x: root.triggerSize; y: root.triggerSize }
                PathLine { x: 0; y: 0 }
            }
        }

        // OS Logo centered in the triangle
        SystemLogo {
            id: logo
            visible: root.showLogo
            x: root.triggerSize * 0.25 - width / 2
            y: root.triggerSize * 0.65 - height / 2
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
    }

    // Mouse interaction - covers entire window (the hover zone)
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.contentVisible ? Qt.PointingHandCursor : Qt.ArrowCursor

        onEntered: {
            root.isHovered = true
            lingerTimer.stop()
            
            // Only show on hover after intro is complete and not dismissed
            if (root.introComplete && !root.contentVisible && !root.dismissed) {
                hoverDelayTimer.start()
            }
        }

        onExited: {
            root.isHovered = false
            hoverDelayTimer.stop()
            
            // Start linger timer when mouse leaves
            if (root.contentVisible && root.introComplete) {
                lingerTimer.restart()
            }
        }

        onClicked: {
            if (root.contentVisible) {
                // Stop all timers
                hoverDelayTimer.stop()
                lingerTimer.stop()
                
                // Mark as dismissed - this disables animations for instant hide
                root.dismissed = true
                root.contentVisible = false
                
                // Show the bar
                root.visibilities.barPinned = true
            }
        }
    }
}
