pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

Scope {
    id: root

    // ═══════════════════════════════════════════════════════════════════════
    // LOCK SCREEN WITH SCREENSAVER INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════
    //
    // This module integrates with ScreensaverService to provide:
    // - Lock screen UI that can be overlaid by screensaver (papertoy)
    // - Coordination between lock state and screensaver state
    // - Activity detection to show/hide lock UI vs screensaver
    //
    // ═══════════════════════════════════════════════════════════════════════

    WlSessionLock {
        id: lock

        signal unlock

        // When lock state changes, coordinate with ScreensaverService
        onLockedChanged: {
            if (!locked) {
                // Successfully unlocked - notify ScreensaverService
                ScreensaverService.unlock();
            }
        }

        LockSurface {
            id: lockSurface
            lock: lock
            pam: pam
        }
    }

    Pam {
        id: pam
        lock: lock
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SCREENSAVER SERVICE CONNECTIONS
    // ═══════════════════════════════════════════════════════════════════════

    Connections {
        target: ScreensaverService

        // ScreensaverService requests lock
        function onLockRequested(): void {
            console.log("Lock: lockRequested received");
            lock.locked = true;
        }

        // ScreensaverService requests unlock (after successful auth)
        function onUnlockRequested(): void {
            console.log("Lock: unlockRequested received");
            lock.unlock();
        }

        // Activity detected while in LockedScreensaver state
        // Need to bring lock UI to foreground
        function onShowLockUI(): void {
            console.log("Lock: showLockUI received");
            lockSurface.ensureInputFocus();
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // IPC HANDLER
    // ═══════════════════════════════════════════════════════════════════════

    IpcHandler {
        target: "lock"

        function lock(): void {
            // Route through ScreensaverService for proper state management
            ScreensaverService.lock();
        }

        function unlock(): void {
            // This is typically called after successful authentication
            // which triggers lock.locked = false via Pam
            // Also notify ScreensaverService directly for state management
            ScreensaverService.unlock();
            lock.unlock();
        }

        function isLocked(): bool {
            return lock.locked;
        }
    }
}
