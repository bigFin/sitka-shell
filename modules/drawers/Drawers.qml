pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.components.effects
import qs.services
import "../../config"
import qs.modules.bar
import qs.modules.launcher as Launcher
import qs.modules.dashboard as Dashboard
import qs.modules.utilities as Utilities
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

Variants {
    model: Quickshell.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        // Aliases for components defined in StyledWindow, needed by sibling components
        property alias visibilities: visibilities
        property alias bar: bar

        Exclusions {
            screen: scope.modelData
            bar: scope.bar
        }

        StyledWindow {
            id: win

            screen: scope.modelData
            name: "drawers"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.session ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            mask: Region {
                x: bar.implicitWidth
                y: Config.border.thickness
                width: win.width - bar.implicitWidth - Config.border.thickness
                height: win.height - Config.border.thickness * 2
                intersection: Intersection.Xor

                regions: regions.instances
            }

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Variants {
                id: regions

                model: panels.children

                Region {
                    required property Item modelData

                    x: modelData.x + bar.implicitWidth
                    y: modelData.y + Config.border.thickness
                    width: modelData.width
                    height: modelData.height
                    intersection: Intersection.Subtract
                }
            }

            // HyprlandFocusGrab {
            //     active: (visibilities.launcher && Config.launcher.enabled) || (visibilities.session && Config.session.enabled)
            //     windows: [win]
            //     onCleared: {
            //         visibilities.launcher = false;
            //         visibilities.session = false;
            //     }
            // }

            StyledRect {
                anchors.fill: parent
                opacity: visibilities.session && Config.session.enabled ? 0.5 : 0
                color: Colours.palette.m3scrim

                Behavior on opacity {
                    Anim {}
                }
            }

            // Global Shader Wrapper
            Item {
                id: globalShaderWrapper
                anchors.fill: parent

                // Shader Controller & Display
                ShellShader {
                    id: shellShader
                    anchors.fill: parent
                    // Visible only when active and compiled
                    visible: shaderActive && resolvedShaderPath !== ""
                    
                    // Inputs
                    source: shaderSource
                }

                // Texture Capture Pipeline
                ShaderEffectSource {
                    id: shaderSource
                    anchors.fill: parent
                    sourceItem: uiContent
                    // Hide original UI when shader is active
                    hideSource: shellShader.visible
                    live: true // Dynamic updates
                    visible: false
                }

                // The Actual UI Content
                Item {
                    id: uiContent
                    anchors.fill: parent
                    
                    Item {
                        id: opaqueDrawerSurface
                        anchors.fill: parent
                        anchors.margins: Config.border.thickness
                        anchors.leftMargin: bar.implicitWidth

                        Launcher.Background {
                            wrapper: panels.launcher
                            x: (opaqueDrawerSurface.width - wrapper.width) / 2
                            y: opaqueDrawerSurface.height - wrapper.height
                            width: wrapper.width
                            height: wrapper.height
                        }

                        Dashboard.Background {
                            wrapper: panels.dashboard
                            x: (opaqueDrawerSurface.width - wrapper.width) / 2
                            y: 0
                            width: wrapper.width
                            height: wrapper.height
                        }
                    }

                    Border {
                        bar: bar
                    }

                    // Backgrounds
                    Item {
                        anchors.fill: parent
                        opacity: Colours.transparency.enabled ? Colours.transparency.base : 1
                        
                        Backgrounds {
                            panels: panels
                            bar: bar
                        }
                    }

                    // Content (Bar, Panels, Interactions)
                    Interactions {
                        screen: scope.modelData
                        popouts: panels.popouts
                        visibilities: visibilities
                        panels: panels
                        bar: bar

                        Panels {
                            id: panels

                            screen: scope.modelData
                            visibilities: visibilities
                            bar: bar
                        }

                        BarWrapper {
                            id: bar

                            anchors.top: parent.top
                            anchors.bottom: parent.bottom

                            screen: scope.modelData
                            visibilities: visibilities
                            popouts: panels.popouts

                            Component.onCompleted: Visibilities.registerBar(scope.modelData, this)
                        }
                    }
                }
            }

            PersistentProperties {
                id: visibilities

                property bool barPinned: Config.bar.persistent
                property bool barShowOnHover: Config.bar.showOnHover
                property int barHoverThreshold: Config.bar.hoverThreshold
                property bool bar
                property bool osd
                property bool session
                property bool launcher
                property bool dashboard
                property bool utilities

                Component.onCompleted: {
                    Visibilities.load(scope.modelData, this);

                    const savedPinned = Visibilities.getBarPinned(scope.modelData.name);
                    if (savedPinned !== null)
                        barPinned = savedPinned;
                }

                onBarPinnedChanged: {
                    Visibilities.setBarPinned(scope.modelData.name, barPinned);
                }
            }
        }

        // Corner trigger for "corner" reveal mode - separate layer-shell surface
        CornerTrigger {
            targetScreen: scope.modelData
            visibilities: scope.visibilities
            barVisible: scope.bar.shouldBeVisible
        }

        // Bottom-right corner trigger for utilities panel
        Utilities.CornerTrigger {
            targetScreen: scope.modelData
            visibilities: scope.visibilities
        }
    }
}
