pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"
import qs.utils

Singleton {
    id: root

    // ═══════════════════════════════════════════════════════════════════════
    // PAPERTOY SERVICE
    // ═══════════════════════════════════════════════════════════════════════
    //
    // Manages papertoy shader wallpaper/screensaver process.
    // Supports two modes:
    //   - Wallpaper mode (layer: background) - behind all windows
    //   - Screensaver mode (layer: overlay) - above all windows
    //
    // The layer can be changed dynamically. When changed, papertoy restarts
    // to apply the new layer setting.
    //
    // ═══════════════════════════════════════════════════════════════════════

    // State
    property alias enabled: props.enabled
    readonly property string shaderPathFile: `${Paths.state}/papertoy/shader.txt`
    
    // Layer: "background" for wallpaper, "overlay" for screensaver
    // Valid values: background, bottom, top, overlay
    property string layer: "background"
    
    // Current shader path - from state file, falls back to config
    property string currentShaderPath: Config.services.papertoy.shaderPath
    
    // Effective command.
    //
    // The packaged papertoy currently does not expose the custom --layer flag
    // described in the screensaver design docs. Passing it makes papertoy exit
    // before rendering anything, so keep the launch command compatible with the
    // installed CLI and let papertoy use its default background layer.
    readonly property list<string> command: {
        let cmd = ["papertoy"];
        if (currentShaderPath)
            cmd.push(currentShaderPath);
        return cmd.concat(Config.services.papertoy.args);
    }

    function setShaderPath(path: string): void {
        currentShaderPath = path;
        // Ensure directory exists and write path
        Quickshell.execDetached(["bash", "-c", `mkdir -p "$(dirname '${shaderPathFile}')" && echo -n "${path}" > "${shaderPathFile}"`]);
        // Restart if running to apply new shader
        if (enabled) {
            enabled = false;
            restartTimer.start();
        }
    }

    // Change layer (triggers restart if running)
    function setLayer(newLayer: string): void {
        if (layer !== newLayer) {
            layer = newLayer;
            // Restart if running to apply new layer
            if (enabled) {
                enabled = false;
                restartTimer.start();
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 100
        onTriggered: root.enabled = true
    }

    PersistentProperties {
        id: props

        property bool enabled

        reloadableId: "papertoy"
    }

    Process {
        running: root.enabled && root.currentShaderPath !== ""
        command: root.command
        
    }

    // Load shader path from state file
    FileView {
        path: root.shaderPathFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const savedPath = text().trim();
            if (savedPath)
                root.currentShaderPath = savedPath;
        }
    }

    IpcHandler {
        target: "papertoy"

        function isEnabled(): bool {
            return root.enabled;
        }

        function toggle(): void {
            root.enabled = !root.enabled;
        }

        function enable(): void {
            root.enabled = true;
        }

        function disable(): void {
            root.enabled = false;
        }

        function getShaderPath(): string {
            return root.currentShaderPath;
        }

        function setShaderPath(path: string): void {
            root.setShaderPath(path);
        }

        function getLayer(): string {
            return root.layer;
        }

        function setLayer(newLayer: string): void {
            root.setLayer(newLayer);
        }
    }
}
