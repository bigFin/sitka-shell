import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils
import qs.services
import "../../config"

// Shell shader effect wrapper - applies configurable post-processing effects
// Supports various presets or auto-compiles custom shaders

ShaderEffect {
    id: root

    // Source is automatically set when used as layer.effect
    property var source

    // Config properties
    property string customShader: Config.appearance.shaders.customShader
    property real intensity: Config.appearance.shaders.intensity
    property bool animateTime: Config.appearance.shaders.animateTime
    property string performanceMode: Config.appearance.shaders.performanceMode
    property color backgroundColor: Colours.palette.m3surface

    // Shader uniforms
    readonly property real iTime: animateTime ? timer.elapsed / 1000.0 : 0.0
    readonly property vector2d iResolution: Qt.vector2d(width, height)

    readonly property bool shaderActive: Config.appearance.shaders.enabled && customShader !== ""

    // Internal property to hold the resolved .qsb path
    property string resolvedShaderPath: ""

    onSourceChanged: console.log("ShellShader source changed:", source)

    function updateShaderPath() {
        console.log("updateShaderPath called. Active:", shaderActive);
        if (!shaderActive) {
            resolvedShaderPath = "";
            return;
        }

        if (customShader !== "") {
            const path = Paths.absolutePath(customShader);
            console.log("Resolved path:", path);
            if (path.endsWith(".qsb")) {
                resolvedShaderPath = `file://${path}`;
            } else {
                // Trigger auto-compilation
                console.log("Starting shader compilation for:", path);
                compilerProcess.inputPath = path;
                compilerProcess.running = true;
            }
        }
    }

    onCustomShaderChanged: { console.log("CustomShader changed:", customShader); updateShaderPath(); }
    onShaderActiveChanged: { console.log("ShaderActive changed:", shaderActive); updateShaderPath(); }
    Component.onCompleted: {
        console.log("ShellShader initialized. Enabled:", shaderActive, "CustomShader:", customShader);
        updateShaderPath();
    }

    fragmentShader: resolvedShaderPath

    Process {
        id: compilerProcess
        // Use bash to invoke the script to ensure environment is right
        command: ["bash", `${Quickshell.shellDir}/scripts/auto-port-shader.sh`, inputPath]
        property string inputPath: ""

        stdout: StdioCollector {
            onStreamFinished: {
                const compiledPath = this.text.trim();
                if (compiledPath !== "") {
                    console.log("Shader compiled successfully:", compiledPath);
                    console.log("Setting resolvedShaderPath to:", `file://${compiledPath}`);
                    root.resolvedShaderPath = `file://${compiledPath}`;
                } else {
                    console.warn("Shader compilation failed: no output path");
                    root.resolvedShaderPath = ""; // Disable shader on failure
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("Shader compilation error:", this.text);
                    // Don't disable immediately on stderr, sometimes it's just warnings
                    // But if stdout is empty, it will be disabled by stdout handler
                }
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                console.error("Shader compilation process failed with exit code:", exitCode);
                root.resolvedShaderPath = ""; // Disable shader on failure
            }
        }
    }

    Timer {
        id: timer
        property real elapsed: 0
        interval: 16
        repeat: true
        // Only run timer if needed and in dynamic mode
        running: root.shaderActive && root.animateTime && root.performanceMode === "dynamic"
        onTriggered: elapsed += interval
    }
}
