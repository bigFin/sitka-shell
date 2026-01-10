# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sitka Shell is a QML/Qt6 desktop shell built on the Quickshell framework, designed for the Niri window manager. It provides a dashboard-based workflow with widgets, drawers, notifications, and system controls.

## Build Commands

```bash
# Production build (recommended)
nix build

# Development mode with hot reload
nix develop
qs -p ./

# Run directly via Nix
nix run

# Non-NixOS systems (Arch, Fedora, etc.)
nix run github:sitka-shell/sitka-shell#arch --impure
```

The build system uses CMake + Ninja, invoked through Nix. Manual CMake builds are possible but Nix is the primary workflow.

## Running the Shell

```bash
# Normal launch
quickshell -c sitka-shell -n
# or
qs -c sitka-shell -n

# IPC commands
qs -c sitka-shell ipc call <target> <function> [args]

# Examples:
qs -c sitka-shell ipc call drawers toggle launcher
qs -c sitka-shell ipc call lock lock
qs -c sitka-shell ipc show  # List all IPC commands
```

## Architecture

### Directory Structure

- **shell.qml** - Entry point, loads root components (Background, Drawers, Lock, Shortcuts)
- **modules/** - UI feature modules organized by function:
  - `bar/` - Top bar with workspaces, clock, tray, status icons
  - `dashboard/` - Main dashboard drawer with tabs and panels
  - `launcher/` - Application launcher with search and actions
  - `drawers/` - Animated drawer panel system
  - `lock/` - Lock screen
  - `notifications/` - Notification popups
  - `osd/` - On-screen display (volume, brightness indicators)
  - `session/` - Power menu / session controls
  - `utilities/widgets/` - Utility widgets (WiFi, Bluetooth, etc.)
- **components/** - Reusable QML components (StyledRect, StyledText, containers, controls)
- **services/** - Backend QML modules for system integration:
  - `Niri.qml` - Niri window manager IPC
  - `WMService.qml` - Window manager abstraction layer
  - `Audio.qml`, `Network.qml`, `Brightness.qml` - System services
- **plugin/src/Sitka/** - C++ QML plugin with performance-critical code:
  - Audio visualization (CAVA, PipeWire, beat detection)
  - Image caching, filesystem access, calculator bindings
- **config/** - Configuration system:
  - `Config.qml` - Main singleton that loads user config
  - `shell.json.example` - Example configuration
  - `shaders/` - 40+ GLSL shader implementations

### Key Patterns

**Singletons**: `Config`, `Paths`, `Colours`, `WMService` are global singletons accessed throughout the codebase.

**Configuration**: User config lives at `~/.config/sitka/shell.json`. The `Config` singleton watches this file and exposes typed properties via sub-configs (AppearanceConfig, BarConfig, etc.).

**Per-Screen UI**: Multi-monitor support uses Quickshell's `Variants { model: Quickshell.screens }` pattern.

**IPC**: External control via `IpcHandler` in `modules/Shortcuts.qml` with targets like "drawers", "launcher", "mpris", "lock".

**Component Pragma**: QML files use `pragma ComponentBehavior: Bound` for type-safe component binding.

### C++ Plugin

The `plugin/` directory contains C++ code compiled into `libsitka`. Key classes:
- `AudioProvider`, `AudioCollector` - PipeWire audio integration
- `CavaProvider`, `BeatTracker` - Audio visualization
- `CachingImageManager` - Image caching system
- `Qalculator` - Calculator engine bindings

C++ uses Qt6 QML module system, LLVM code style, C++20 standard.

## Code Style

**QML**: PascalCase for components, camelCase for properties, 4-space indentation.

**C++**: LLVM style with 120 column limit. Use `.clang-format` for formatting.

**Commits**: Conventional commit format with prefixes (feat, fix, perf, docs, etc.).
