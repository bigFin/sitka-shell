# Sitka Shell

Sitka Shell is a Quickshell desktop shell for the Niri window manager. It is
forked from Niri Caelestia Shell and Caelestia Shell, with the original dots
management and CLI removed.

The project is still experimental. The current focus is a Niri-first workflow
with a left bar, drawers, launcher, dashboard, notifications, lock screen,
wallpaper tools, and optional shader effects.

## Status

This is a personal shell, not a polished distribution. Expect rough edges,
especially around multi-monitor behavior, focus handling for layer-shell
windows, and compositor-specific APIs.

## Dependencies

Runtime dependencies:

```sh
quickshell-git networkmanager fish glibc qt6-declarative gcc-libs cava libcava aubio libpipewire lm-sensors ddcutil brightnessctl material-symbols caskaydia-cove-nerd grim swappy app2unit libqalculate
```

Build dependencies:

```sh
cmake ninja
```

Notes:

- `quickshell-git` is required.
- `cava`, `libcava`, `aubio`, and `libpipewire` are used by the audio visualizer.
- `grim` and `swappy` are used by screenshot tooling.
- `material-symbols` and `caskaydia-cove-nerd` provide the expected fonts/icons.

## Install

Clone the repository where Quickshell can find it:

```sh
mkdir -p "$XDG_CONFIG_HOME/quickshell"
cd "$XDG_CONFIG_HOME/quickshell"
git clone https://github.com/sitka-shell/sitka-shell
cd sitka-shell
```

Build with Nix:

```sh
nix build
```

On non-NixOS systems, use the `arch` flake output so OpenGL is wrapped with
`nixGL`:

```sh
nix run github:sitka-shell/sitka-shell#arch --impure
```

## Run

Start the shell with either `quickshell` or `qs`:

```sh
quickshell -c sitka-shell -n
```

Niri startup example:

```kdl
spawn-at-startup "quickshell" "-c" "sitka-shell" "-n"
```

For the Nix `arch` output:

```kdl
spawn-at-startup "nix" "run" "github:sitka-shell/sitka-shell#arch" "--impure"
```

## Development

Enter the development shell, then run the local QML directly:

```sh
nix develop
qs -p ./
```

This loads the current checkout instead of the packaged shell. The Sitka QML
plugin and extra binaries are provided by the Nix development environment.

## Configuration

User configuration lives at:

```sh
~/.config/sitka/shell.json
```

The commented example is in:

```sh
config/shell.json.example
```

Useful settings:

```json
{
  "appearance": {
    "shaders": {
      "enabled": false,
      "customShader": "~/.config/sitka/shaders/retro-terminal.glsl",
      "animateTime": false,
      "performanceMode": "off"
    }
  },
  "background": {
    "visualiser": {
      "enabled": false,
      "autoHide": true
    }
  },
  "services": {
    "papertoy": {
      "shaderPath": "",
      "args": []
    }
  }
}
```

Performance guidance:

- Leave `appearance.shaders.enabled` off unless you are actively using drawer
  post-processing.
- The drawer shader overlay only runs when `performanceMode` is set to
  `"dynamic"`. Keep it `"off"` for normal use.
- Keep `background.visualiser.enabled` off unless the audio visualizer is needed.
- Disable Papertoy from the bar when not using shader wallpaper/screensaver
  effects.

## IPC

List available IPC targets:

```sh
qs -c sitka-shell ipc show
```

Call IPC functions with:

```sh
quickshell -c sitka-shell ipc call <target> <function> [args...]
```

Examples:

```sh
sitka-shell ipc call lock lock
qs -c sitka-shell ipc call drawers toggle launcher
```

Niri lock keybind example:

```kdl
binds {
    Mod+L { spawn "sitka-shell" "ipc" "call" "lock" "lock"; }
}
```

## Wallpapers and Profile Image

The dashboard profile image is read from `~/.face`.

Wallpapers are read from `~/Pictures/Wallpapers` by default. Change the path in
`~/.config/sitka/shell.json` if your wallpaper directory lives elsewhere.

The launcher command `> wallpaper` opens wallpaper actions.

## Known Issues

1. Multi-monitor behavior still needs cleanup.
2. The task manager currently has no Intel GPU support.
3. The workspace bar needs refactoring.
4. Screenshot window grabbing is limited by Niri behavior.
5. Focus handling for Quickshell windows such as power menu, task manager, and
   settings is awkward under Niri.
6. Quickshell can still crash due to upstream issues.

## Credits

- [Quickshell](https://github.com/quickshell/quickshell)
- [Caelestia Shell](https://github.com/caelestia-shell/caelestia-shell)
- [Niri Caelestia Shell](https://github.com/0lxy/niri-caelestia-shell)
- [Niri](https://github.com/YaLTeR/niri)
- Upstream contributors
