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
        
        if (hasPPD) {
            ppdService.profile = newProfile;
        } else if (hasTLP) {
            root.manualProfile = newProfile;
            
            let cmd = (newProfile === powerSaver) ? "pkexec tlp bat" : "pkexec tlp ac";
            
            tlpProcess.command = ["sh", "-c", cmd];
            tlpProcess.running = true;
            
            notifyProcess.command = ["notify-send", "-a", "Sitka Shell", "Power Management", "Switching to " + profileToString(newProfile) + " mode..."];
            notifyProcess.running = true;
        } else {
            root.manualProfile = newProfile;
            notifyProcess.command = ["notify-send", "-a", "Sitka Shell", "Power Management", "No power backend available; showing " + profileToString(newProfile) + " locally."];
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
        try {
            ppdService = Qt.createQmlObject('import Quickshell.Services.PowerProfiles; PowerProfiles {}', root, "DynamicPowerProfiles");
        } catch (e) {
            checkTlpBinary.running = true;
        }
    }

    Process {
        id: checkTlpBinary
        command: ["sh", "-c", "command -v tlp || test -x /usr/bin/tlp || test -x /bin/tlp"]
        onExited: exitCode => {
            if (exitCode === 0) {
                root.hasTLP = true;
            } else {
                checkNixos.running = true;
            }
        }
    }

    Process {
        id: checkNixos
        command: ["sh", "-c", ". /etc/os-release 2>/dev/null && test \"${ID:-}\" = nixos"]
    }

    Process {
        id: tlpProcess
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
