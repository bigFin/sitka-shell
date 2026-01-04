import Quickshell.Io

JsonObject {
    // Legacy options (for backwards compatibility)
    property bool persistent: false  // Bar starts hidden by default (use corner trigger to show)
    property bool showOnHover: false  // Deprecated: use revealMode instead
    property int dragThreshold: 20
    property int hoverThreshold: 200

    // New bar behavior options
    property string revealMode: "corner"  // "corner" | "hover" | "always"
    property bool overlayMode: true       // true = bar overlays windows (no exclusive zone change)

    // Corner trigger settings (when revealMode === "corner")
    property CornerTrigger cornerTrigger: CornerTrigger {}

    property ScrollActions scrollActions: ScrollActions {}
    property Workspaces workspaces: Workspaces {}
    property Tray tray: Tray {}
    property Status status: Status {}
    property Clock clock: Clock {}
    property Sizes sizes: Sizes {}

    property list<var> entries: [
        {
            id: "workspaces",
            enabled: true
        },
        {
            id: "spacer",
            enabled: true
        },
        {
            id: "activeWindow",
            enabled: true
        },
        {
            id: "spacer",
            enabled: true
        },
        {
            id: "tray",
            enabled: true
        },
        {
            id: "clock",
            enabled: true
        },
        {
            id: "statusIcons",
            enabled: true
        },
        {
            id: "power",
            enabled: true
        },
        {
            id: "controlcenter",
            enabled: true
        },
        {
            id: "papertoy",
            enabled: false
        },
        {
            id: "idleInhibitor",
            enabled: false
        },
        {
            id: "screenRecorder",
            enabled: false
        },
        {
            id: "logoToggle",  // OS logo that toggles bar pinned state (replaces pin)
            enabled: true
        }
    ]

    component ScrollActions: JsonObject {
        property bool workspaces: true
        property bool volume: true
        property bool brightness: true
    }

    component Workspaces: JsonObject {
        property int shown: 4
        property bool activeIndicator: true
        property bool occupiedBg: true
        property bool showWindows: true
        property bool windowIconImage: true // false -> MaterialIcons, true -> IconImage
        property int windowIconGap: 5
        property int windowIconSize: 30
        property bool groupIconsByApp: false
        property bool groupingRespectsLayout: true
        property bool focusedWindowBlob: true
        property bool windowRighClickContext: true
        property bool windowContextDefaultExpand: true
        property bool doubleClickToCenter: true
        property int windowContextWidth: 250
        property bool activeTrail: false
        property bool pagerActive: true
        property string label: "◦" // ""
        property string occupiedLabel: "⊙" // "󰮯"
        property string activeLabel: "󰮯" //Handled in workspace.qml
    }

    component Tray: JsonObject {
        property bool background: false
        property bool recolour: false
    }

    component Status: JsonObject {
        property bool showAudio: false
        property bool showMicrophone: false
        property bool showKbLayout: false
        property bool showNetwork: true
        property bool showBluetooth: true
        property bool showBattery: true
        property bool showLockStatus: true
    }

    component Clock: JsonObject {
        property bool showIcon: true
    }

    component Sizes: JsonObject {
        property int innerWidth: 40
        property int windowPreviewSize: 400
        property int trayMenuWidth: 300
        property int batteryWidth: 250
        property int networkWidth: 320
    }

    component CornerTrigger: JsonObject {
        property int size: 48              // Size of the corner hotspot
        property int hoverExpand: 8        // How much it expands on hover
        property bool showLogo: true       // Show OS logo in corner
        property real logoScale: 0.6       // Scale of logo relative to corner size
    }
}
