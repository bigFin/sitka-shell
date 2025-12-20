pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../config"
import qs.utils

Singleton {
    id: root

    // State
    property alias enabled: props.enabled
    readonly property string shaderPathFile: `${Paths.state}/papertoy/shader.txt`
    
    // Current shader path - from state file, falls back to config
    property string currentShaderPath: Config.services.papertoy.shaderPath
    
    // Effective command
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
    }
}
