import Quickshell.Io

JsonObject {
    // Whether screensaver functionality is enabled
    property bool enabled: true
    
    // Auto-lock: require password after screensaver activates
    property bool autoLockEnabled: true
    
    // Delay (in seconds) before auto-lock after screensaver starts
    // 0 = immediate lock when screensaver starts
    // 300 = 5 minutes of screensaver before requiring password
    property int autoLockDelay: 300
    
    // How long (in seconds) before screensaver re-activates on lock screen
    // This prevents burn-in on the lock screen itself
    property int screensaverWhileLockedTimeout: 60
    
    // Whether to pause papertoy when monitors are powered off (saves resources)
    property bool pausePapertoyOnDpms: true

    // When true, papertoy moves to background layer during lock UI activity
    // When false, papertoy is disabled during lock UI activity (saves GPU)
    property bool papertoyAsBackground: false
}
