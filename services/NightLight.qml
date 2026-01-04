pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property alias enabled: props.enabled
    property alias temperature: props.temperature

    readonly property int minTemp: 2500
    readonly property int maxTemp: 6500
    readonly property int defaultTemp: 4500

    PersistentProperties {
        id: props

        property bool enabled: false
        property int temperature: 4500

        reloadableId: "nightLight"
    }

    // Apply night light using gammastep
    Process {
        id: applyProc
        command: ["gammastep", "-O", root.temperature.toString()]
    }

    // Reset to normal
    Process {
        id: resetProc
        command: ["gammastep", "-x"]
    }

    // Watch for enabled changes
    onEnabledChanged: {
        if (enabled) {
            applyProc.running = true
        } else {
            resetProc.running = true
        }
    }

    // Watch for temperature changes
    onTemperatureChanged: {
        if (enabled) {
            applyProc.running = true
        }
    }

    function toggle(): void {
        enabled = !enabled
    }

    function setTemperature(temp: int): void {
        temperature = Math.max(minTemp, Math.min(maxTemp, temp))
    }

    function warmer(): void {
        setTemperature(temperature - 500)
    }

    function cooler(): void {
        setTemperature(temperature + 500)
    }

    IpcHandler {
        target: "nightLight"

        function isEnabled(): bool {
            return root.enabled
        }

        function toggle(): void {
            root.toggle()
        }

        function setTemp(temp: int): void {
            root.setTemperature(temp)
        }
    }
}
