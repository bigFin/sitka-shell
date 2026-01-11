# Screensaver & Lock Screen Integration

This document describes the screensaver/lock screen system in sitka-shell, designed for OLED burn-in protection on Wayland compositors (specifically niri).

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              IDLE DETECTION                              │
│                                                                          │
│    swayidle ──────────────────────────────────────────────────────────► │
│       │                                                                  │
│       │ timeout 300s                                                     │
│       │ resume                                                           │
│       │ timeout 660s (dpms)                                              │
│       │ before-sleep                                                     │
│       ▼                                                                  │
│    sitka-ipc ──► ScreensaverService ──► Papertoy (overlay layer)        │
│                         │                                                │
│                         │ lockRequested                                  │
│                         ▼                                                │
│                      Lock.qml (WlSessionLock)                           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Components

### 1. swayidle (System Service)
Wayland-native idle detector that respects idle inhibitors (video players, games, presentations).

**Key features:**
- Timeout-based events
- Resume detection
- before-sleep hook for suspend/hibernate

### 2. ScreensaverService.qml (State Machine)
Central coordinator managing state transitions between:

| State | Description |
|-------|-------------|
| `Active` | Normal desktop use |
| `Screensaver` | Screensaver running (papertoy on overlay), not locked |
| `Locked` | Lock screen shown, no screensaver overlay |
| `LockedScreensaver` | Lock screen with screensaver overlay (burn-in protection) |
| `DpmsOff` | Monitors powered off, papertoy paused |

### 3. Papertoy Service
Manages the papertoy shader wallpaper/screensaver process.

**Key enhancement:** `layer` property
- `background` - Behind all windows (wallpaper mode)
- `overlay` - Above all windows (screensaver mode)

### 4. Lock.qml (WlSessionLock)
Wayland session lock surface for authentication.

## State Transitions

```
                    ┌──────────────────────────────────────┐
                    │                                      │
                    ▼                                      │
              ┌──────────┐                                 │
              │  Active  │◄────────────────────────────────┤
              └────┬─────┘                                 │
                   │                                       │
      idle timeout │                      unlock           │
                   ▼                                       │
           ┌─────────────────┐                             │
           │  Screensaver    │                             │
           │  (overlay layer)│                             │
           └────┬───────┬────┘                             │
                │       │                                  │
   activity     │       │ auto-lock timer                  │
   (no auto-lock)       │                                  │
                │       ▼                                  │
                │  ┌────────────────────┐                  │
                │  │ LockedScreensaver  │                  │
                │  │  (overlay layer)   │                  │
                │  └─────────┬──────────┘                  │
                │            │                             │
                │   activity │                             │
                │            ▼                             │
                │       ┌──────────┐      unlock           │
                └──────►│  Locked  │───────────────────────┘
                        └──────────┘
```

## Configuration

### shell.json
```json
{
  "screensaver": {
    "enabled": true,
    "autoLockEnabled": true,
    "autoLockDelay": 0,
    "screensaverWhileLockedTimeout": 30,
    "pausePapertoyOnDpms": true
  },
  "services": {
    "papertoy": {
      "shaderPath": "/path/to/shader.glsl",
      "args": []
    }
  }
}
```

| Option | Description | Default |
|--------|-------------|---------|
| `enabled` | Enable screensaver system | `true` |
| `autoLockEnabled` | Auto-lock when screensaver activates | `true` |
| `autoLockDelay` | Seconds before auto-lock (0 = immediate) | `0` |
| `screensaverWhileLockedTimeout` | Seconds before screensaver re-enables on lock screen | `30` |
| `pausePapertoyOnDpms` | Pause papertoy when monitors off | `true` |

## IPC Commands

All commands use `sitka-ipc` (or `qs -p <shell-path> ipc`):

```bash
# Screensaver Service
sitka-ipc call screensaver enable           # Trigger screensaver
sitka-ipc call screensaver activityDetected # Simulate activity
sitka-ipc call screensaver dpmsOff          # Monitor power off
sitka-ipc call screensaver dpmsOn           # Monitor power on
sitka-ipc call screensaver lock             # Lock screen
sitka-ipc call screensaver getState         # Get current state
sitka-ipc call screensaver isScreensaverActive
sitka-ipc call screensaver isLocked

# Papertoy Service
sitka-ipc call papertoy enable
sitka-ipc call papertoy disable
sitka-ipc call papertoy toggle
sitka-ipc call papertoy isEnabled
sitka-ipc call papertoy getLayer            # background/overlay
sitka-ipc call papertoy setLayer overlay    # Switch layer
sitka-ipc call papertoy getShaderPath
sitka-ipc call papertoy setShaderPath /path/to/shader.glsl

# Lock Service
sitka-ipc call lock lock
sitka-ipc call lock unlock
sitka-ipc call lock isLocked
```

## NixOS/Home Manager Integration

### Using the Built-in Home Manager Module

The easiest way to set up the screensaver is via sitka-shell's home-manager module:

```nix
# flake.nix inputs
inputs.sitka-shell.url = "github:your-username/sitka-shell";

# home.nix
{ inputs, ... }: {
  imports = [ inputs.sitka-shell.homeManagerModules.default ];
  
  programs.sitka = {
    enable = true;
    
    # Screensaver/swayidle integration
    swayidle = {
      enable = true;
      screensaverTimeout = 300;  # 5 minutes
      dpmsTimeout = 660;         # 11 minutes
      lockOnSleep = true;
    };
    
    # Shell settings
    settings = {
      screensaver = {
        enabled = true;
        autoLockEnabled = true;
        autoLockDelay = 0;
        screensaverWhileLockedTimeout = 30;
        pausePapertoyOnDpms = true;
      };
      services.papertoy = {
        shaderPath = "/path/to/shader.glsl";
        args = [];
      };
    };
  };
}
```

### Manual swayidle Service Module

```nix
# modules/home-manager/swayidle.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  # Get sitka-shell package for the sitka-ipc wrapper
  sitkaShell = lib.inputs.sitka-shell.packages.${pkgs.system}.default;

  # Configurable timeouts (in seconds)
  screensaverTimeout = 300;  # 5 minutes
  dpmsTimeout = 660;         # 11 minutes
  
  # IPC commands using sitka-ipc wrapper
  screensaverEnableCmd = "${sitkaShell}/bin/sitka-ipc call screensaver enable";
  activityDetectedCmd = "${sitkaShell}/bin/sitka-ipc call screensaver activityDetected";
  dpmsOffCmd = "${sitkaShell}/bin/sitka-ipc call screensaver dpmsOff";
  lockCmd = "${sitkaShell}/bin/sitka-ipc call screensaver lock";
  
  swayidleCmd = lib.concatStringsSep " " [
    "${pkgs.swayidle}/bin/swayidle -w"
    "timeout ${toString screensaverTimeout} '${screensaverEnableCmd}'"
    "resume '${activityDetectedCmd}'"
    "timeout ${toString dpmsTimeout} '${dpmsOffCmd}'"
    "before-sleep '${lockCmd}'"
  ];
in {
  home.packages = [ pkgs.swayidle ];

  systemd.user.services.swayidle = {
    Unit = {
      Description = "Idle manager for Wayland - sitka-shell screensaver integration";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = swayidleCmd;
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
```

## Dependencies

### Required
- **swayidle** - Wayland idle detector
- **papertoy** - Shadertoy-compatible shader renderer (with `--layer` support)
- **sitka-shell** - This shell (provides ScreensaverService, Papertoy service, Lock)

### Papertoy --layer Feature

The `--layer` CLI option is **required** for overlay mode. This is a custom addition to papertoy.

```bash
# Usage
papertoy --layer overlay /path/to/shader.glsl

# Available layers
papertoy --layer background  # Default, behind all windows
papertoy --layer bottom      # Above background
papertoy --layer top         # Below overlay
papertoy --layer overlay     # Above all windows (screensaver mode)
```

**Status:** This feature is not yet upstream. Use the fork at:
- Fork: `github:bigFin/papertoy` (branch: `feature/layer-option` when created)
- Upstream: `github:sin-ack/papertoy`

## Niri Configuration

### Lock Keybind
```kdl
binds {
    Mod+Alt+L allow-when-locked=true {
        spawn "sitka-ipc" "call" "lock" "lock"
    }
}
```

## Troubleshooting

### Check Service Status
```bash
systemctl --user status swayidle
```

### View Logs
```bash
journalctl --user -u swayidle -f
```

### Test IPC Manually
```bash
# Get current state
sitka-ipc call screensaver getState

# Trigger screensaver manually
sitka-ipc call screensaver enable

# Check papertoy layer
sitka-ipc call papertoy getLayer
```

### Common Issues

**IPC fails with "No running instances"**
- sitka-shell is not running
- Restart: `pkill -f quickshell; sitka-shell &`

**Screensaver appears behind windows**
- Papertoy layer is not set to "overlay"
- Check: `sitka-ipc call papertoy getLayer`
- This requires papertoy with `--layer` support

**swayidle not triggering**
- Check idle inhibitors: video players, presentations
- Verify service is running: `systemctl --user status swayidle`
