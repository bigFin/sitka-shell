pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "../config"

Singleton {
    id: root

    // ═══════════════════════════════════════════════════════════════════════
    // STATE MACHINE
    // ═══════════════════════════════════════════════════════════════════════
    //
    // States:
    //   Active          - Normal desktop use
    //   Screensaver     - Screensaver running (papertoy enabled), not locked
    //   Locked          - Lock screen shown, no screensaver overlay
    //   LockedScreensaver - Lock screen with screensaver overlay (burn-in protection)
    //   DpmsOff         - Monitors powered off, papertoy paused
    //
    // Transitions:
    //   Active → Screensaver (idle timeout via swayidle)
    //   Active → Locked (manual lock via Super+Alt+L)
    //   Screensaver → LockedScreensaver (auto-lock delay timer)
    //   Screensaver → Active (activity + no auto-lock)
    //   Screensaver → Locked (activity + auto-lock, shows lock UI)
    //   Locked → LockedScreensaver (screensaver timeout while locked)
    //   LockedScreensaver → Locked (activity, shows lock UI)
    //   Locked → Active (successful unlock)
    //   Any → DpmsOff (dpms timeout)
    //   DpmsOff → (previous state) (activity)
    //
    // ═══════════════════════════════════════════════════════════════════════

    enum State {
        Active,
        Screensaver,
        Locked,
        LockedScreensaver,
        DpmsOff
    }

    // Current state
    property int state: ScreensaverService.State.Active
    
    // State before DPMS off (to restore)
    property int stateBeforeDpms: ScreensaverService.State.Active

    // Track user's original papertoy layer setting
    property string userPapertoyLayer: "background"

    // Track if user had papertoy enabled before we touched it
    property bool userPapertoyWasEnabled: false
    
    // Track if screensaver activated papertoy (so we know to disable on exit)
    property bool screensaverActivatedPapertoy: false

    // Track if we temporarily disabled papertoy during lock UI (for re-enable)
    property bool papertoyTemporarilyDisabled: false

    // Configuration aliases
    readonly property bool autoLockEnabled: Config.screensaver.autoLockEnabled
    readonly property int autoLockDelay: Config.screensaver.autoLockDelay * 1000 // convert to ms
    readonly property int screensaverWhileLockedTimeout: Config.screensaver.screensaverWhileLockedTimeout * 1000
    readonly property bool pausePapertoyOnDpms: Config.screensaver.pausePapertoyOnDpms
    readonly property bool papertoyAsBackground: Config.screensaver.papertoyAsBackground

    // Signals for Lock.qml to listen to
    signal lockRequested()
    signal unlockRequested()
    signal showLockUI()  // When activity detected during locked+screensaver

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API (called via IPC from swayidle)
    // ═══════════════════════════════════════════════════════════════════════

    function enableScreensaver(): void {
        console.log("ScreensaverService: enableScreensaver called, current state:", stateToString(state));
        
        if (state === ScreensaverService.State.Active) {
            // Save user's papertoy state (enabled and layer)
            userPapertoyWasEnabled = Papertoy.enabled;
            userPapertoyLayer = Papertoy.layer;
            
            // Switch to overlay layer for fullscreen screensaver
            Papertoy.setLayer("overlay");
            
            if (!Papertoy.enabled) {
                Papertoy.enabled = true;
                screensaverActivatedPapertoy = true;
            }
            state = ScreensaverService.State.Screensaver;
            
            // Start auto-lock timer if enabled
            if (autoLockEnabled && autoLockDelay > 0) {
                autoLockTimer.interval = autoLockDelay;
                autoLockTimer.start();
            } else if (autoLockEnabled && autoLockDelay === 0) {
                // Immediate auto-lock
                transitionToLocked(false);
            }
        } else if (state === ScreensaverService.State.Locked) {
            // Already locked, add screensaver overlay
            enablePapertoyIfNeeded();
            state = ScreensaverService.State.LockedScreensaver;
        }
    }

    function activityDetected(): void {
        console.log("ScreensaverService: activityDetected, current state:", stateToString(state));
        
        switch (state) {
            case ScreensaverService.State.Screensaver:
                autoLockTimer.stop();
                if (autoLockEnabled) {
                    // Activity during screensaver with auto-lock: lock and show UI immediately
                    transitionToLocked(true);
                } else {
                    // No auto-lock: just dismiss screensaver
                    restorePapertoyState();
                    state = ScreensaverService.State.Active;
                }
                break;
                
            case ScreensaverService.State.LockedScreensaver:
                // Activity while locked+screensaver: hide screensaver, show lock UI
                // Temporarily hide papertoy so lock UI is visible
                if (papertoyAsBackground) {
                    Papertoy.setLayer("background");
                } else {
                    Papertoy.enabled = false;
                    papertoyTemporarilyDisabled = true;
                }
                state = ScreensaverService.State.Locked;
                showLockUI();
                // Start timer to re-enable screensaver if no unlock
                screensaverWhileLockedTimer.restart();
                break;
                
            case ScreensaverService.State.DpmsOff:
                // Wake from DPMS
                if (pausePapertoyOnDpms && (stateBeforeDpms === ScreensaverService.State.Screensaver || 
                    stateBeforeDpms === ScreensaverService.State.LockedScreensaver)) {
                    Papertoy.enabled = true;
                }
                state = stateBeforeDpms;
                // Treat as activity in the restored state
                activityDetected();
                break;
                
            case ScreensaverService.State.Locked:
                // Already showing lock UI, restart screensaver timer
                screensaverWhileLockedTimer.restart();
                break;
        }
    }

    function dpmsOff(): void {
        console.log("ScreensaverService: dpmsOff called, current state:", stateToString(state));
        
        if (state !== ScreensaverService.State.DpmsOff) {
            stateBeforeDpms = state;
            
            // Pause papertoy to save resources
            if (pausePapertoyOnDpms && Papertoy.enabled) {
                Papertoy.enabled = false;
            }
            
            state = ScreensaverService.State.DpmsOff;
        }
    }

    function dpmsOn(): void {
        console.log("ScreensaverService: dpmsOn called");
        activityDetected();  // Treat DPMS on as activity
    }

    // Called by Lock.qml when lock is requested (manual or auto)
    function lock(): void {
        console.log("ScreensaverService: lock called, current state:", stateToString(state));

        autoLockTimer.stop();

        if (state === ScreensaverService.State.Active) {
            // Save user's papertoy state before we potentially modify it
            // This ensures proper restoration on unlock
            userPapertoyWasEnabled = Papertoy.enabled;
            userPapertoyLayer = Papertoy.layer;
            // Reset activation flag since we're starting fresh
            screensaverActivatedPapertoy = false;

            state = ScreensaverService.State.Locked;
            lockRequested();
            // Start timer for screensaver overlay on lock screen
            screensaverWhileLockedTimer.start();
        } else if (state === ScreensaverService.State.Screensaver) {
            transitionToLocked(false);
        } else if (state === ScreensaverService.State.DpmsOff) {
            // Lock requests while monitors are off (before-sleep/manual) must still lock now.
            stateBeforeDpms = ScreensaverService.State.Locked;
            state = ScreensaverService.State.Locked;
            lockRequested();
            screensaverWhileLockedTimer.start();
        }
    }

    // Called by Lock.qml when unlock succeeds
    function unlock(): void {
        console.log("ScreensaverService: unlock called");

        autoLockTimer.stop();
        screensaverWhileLockedTimer.stop();
        // Clean up temporary disable flag
        papertoyTemporarilyDisabled = false;
        restorePapertoyState();
        state = ScreensaverService.State.Active;
        unlockRequested();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // INTERNAL HELPERS
    // ═══════════════════════════════════════════════════════════════════════

    function transitionToLocked(showUi: bool): void {
        lockRequested();

        if (showUi) {
            // Show lock UI immediately.
            if (papertoyAsBackground) {
                Papertoy.setLayer("background");
            } else {
                Papertoy.enabled = false;
                papertoyTemporarilyDisabled = true;
            }
            state = ScreensaverService.State.Locked;
            showLockUI();
            screensaverWhileLockedTimer.restart();
        } else {
            // Keep screensaver overlay for burn-in protection until activity.
            state = ScreensaverService.State.LockedScreensaver;
        }
    }

    function enablePapertoyIfNeeded(): void {
        // Save user's current papertoy state BEFORE any changes
        // This ensures we can properly restore on unlock
        // Track original layer only on first call (when transitioning from Locked)
        if (state === ScreensaverService.State.Locked) {
            userPapertoyLayer = Papertoy.layer;
            userPapertoyWasEnabled = Papertoy.enabled;
        }

        // Switch to overlay layer for screensaver
        Papertoy.setLayer("overlay");

        // Only enable if not already running
        if (!Papertoy.enabled) {
            Papertoy.enabled = true;
            screensaverActivatedPapertoy = true;
        }
    }

    function restorePapertoyState(): void {
        // Restore layer first
        Papertoy.setLayer(userPapertoyLayer);
        
        // Only disable if we enabled it
        if (screensaverActivatedPapertoy && !userPapertoyWasEnabled) {
            Papertoy.enabled = false;
        }
        screensaverActivatedPapertoy = false;
    }

    function stateToString(s: int): string {
        switch (s) {
            case ScreensaverService.State.Active: return "Active";
            case ScreensaverService.State.Screensaver: return "Screensaver";
            case ScreensaverService.State.Locked: return "Locked";
            case ScreensaverService.State.LockedScreensaver: return "LockedScreensaver";
            case ScreensaverService.State.DpmsOff: return "DpmsOff";
            default: return "Unknown";
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // TIMERS
    // ═══════════════════════════════════════════════════════════════════════

    // Auto-lock timer: fires after screensaver has been active for autoLockDelay
    Timer {
        id: autoLockTimer
        repeat: false
        onTriggered: {
            console.log("ScreensaverService: autoLockTimer triggered");
            if (root.state === ScreensaverService.State.Screensaver) {
                root.transitionToLocked(false);
            }
        }
    }

    // Screensaver-while-locked timer: re-enables screensaver overlay on lock screen
    Timer {
        id: screensaverWhileLockedTimer
        interval: root.screensaverWhileLockedTimeout
        repeat: false
        onTriggered: {
            console.log("ScreensaverService: screensaverWhileLockedTimer triggered");
            if (root.state === ScreensaverService.State.Locked) {
                // Re-enable papertoy if we temporarily disabled it
                if (root.papertoyTemporarilyDisabled) {
                    Papertoy.enabled = true;
                    root.papertoyTemporarilyDisabled = false;
                }
                // Ensure layer is overlay for burn-in protection
                Papertoy.setLayer("overlay");
                root.state = ScreensaverService.State.LockedScreensaver;
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // IPC HANDLER
    // ═══════════════════════════════════════════════════════════════════════

    IpcHandler {
        target: "screensaver"

        function enable(): void {
            root.enableScreensaver();
        }

        function activityDetected(): void {
            root.activityDetected();
        }

        function dpmsOff(): void {
            root.dpmsOff();
        }

        function dpmsOn(): void {
            root.dpmsOn();
        }

        function lock(): void {
            root.lock();
        }

        function getState(): string {
            return root.stateToString(root.state);
        }

        function isScreensaverActive(): bool {
            return root.state === ScreensaverService.State.Screensaver || 
                   root.state === ScreensaverService.State.LockedScreensaver;
        }

        function isLocked(): bool {
            return root.state === ScreensaverService.State.Locked || 
                   root.state === ScreensaverService.State.LockedScreensaver;
        }
    }

    Component.onCompleted: {
        console.log("ScreensaverService: Initialized");
    }
}
