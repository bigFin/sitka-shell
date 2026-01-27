pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    // Constants matching Quickshell's PowerProfile enum
    readonly property int powerSaver: 0
    readonly property int balanced: 1
    readonly property int performance: 2

    // Dynamically load PowerProfiles to avoid crash if module is missing
    property var ppdService: null
    readonly property bool hasPPD: ppdService !== null && ppdService.active
    property bool hasTLP: false

    readonly property string backend: {
        if (hasPPD) return "power-profiles-daemon";
        if (hasTLP) return "tlp";
        return "none";
    }

    // Manual override state
    property int manualProfile: -1 // -1 means follow UPower automatic logic

    property int profile: {
        let p = balanced;
        if (hasPPD) p = ppdService.profile;
        else if (manualProfile !== -1) p = manualProfile;
        else if (hasTLP) {
            p = UPower.onBattery ? powerSaver : balanced;
        }
        return p;
    }

    readonly property bool performanceDegraded: hasPPD && ppdService.degradationReason !== 0
    readonly property string degradationReason: {
        if (!hasPPD) return "";
        return ppdService.degradationReason !== 0 ? "Hardware limitation" : "";
    }

    function setProfile(newProfile: int): void {
        console.log("Power: setProfile called with " + profileToString(newProfile) + " | Backend: " + backend);
        
        if (hasPPD) {
            ppdService.profile = newProfile;
        } else if (hasTLP || backend === "none") {
            root.manualProfile = newProfile;
            
            let cmd = (newProfile === powerSaver) ? "pkexec tlp bat" : "pkexec tlp ac";
            
            console.log("Power: Executing " + cmd);
            tlpProcess.command = ["sh", "-c", cmd];
            tlpProcess.running = true;
            
            notifyProcess.command = ["notify-send", "-a", "Sitka Shell", "Power Management", "Switching to " + profileToString(newProfile) + " mode..."];
            notifyProcess.running = true;
        }
    }

    function profileToString(p: int): string {
        if (p === powerSaver) return "Power Saver";
        if (p === performance) return "Performance";
        if (p === balanced) return "Balanced";
        return "Unknown";
    }

    Component.onCompleted: {
        console.log("Power: Singleton completed");
        try {
            ppdService = Qt.createQmlObject('import Quickshell.Services.PowerProfiles; PowerProfiles {}', root, "DynamicPowerProfiles");
            console.log("Power: PowerProfiles detected");
        } catch (e) {
            console.log("Power: PowerProfiles module missing, using TLP fallback");
            checkTlpBinary.running = true;
        }
    }

    Process {
        id: checkTlpBinary
        command: ["sh", "-c", "command -v tlp || test -x /usr/bin/tlp || test -x /bin/tlp"]
        onRunningChanged: if (!running) {
            if (checkTlpBinary.exitCode === 0) {
                console.log("Power: TLP binary detected");
                root.hasTLP = true;
            } else {
                console.log("Power: TLP binary not found, checking if we should force TLP backend");
                checkNixos.running = true;
            }
        }
    }

    Process {
        id: checkNixos
        command: ["test", "-f", "/etc/NIXOS"]
        onRunningChanged: if (!running) {
            if (checkNixos.exitCode !== 0) {
                console.log("Power: Not on NixOS, force-enabling TLP backend");
                root.hasTLP = true;
            }
        }
    }

    Process {
        id: tlpProcess
        onRunningChanged: if (!running) console.log("Power: TLP command finished with exit code: " + tlpProcess.exitCode)
    }

    Process {
        id: notifyProcess
    }

    Connections {
        target: UPower
        function onOnBatteryChanged(): void {
            if (hasTLP) root.manualProfile = -1;
        }
    }
}
