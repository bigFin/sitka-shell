<h1 align=center>🌲 Sitka Shell</h1>

<div align=center>

![GitHub last commit](https://img.shields.io/github/last-commit/jutraim/sitka-shell?style=for-the-badge&labelColor=101418&color=9ccbfb)
![GitHub Repo stars](https://img.shields.io/github/stars/jutraim/sitka-shell?style=for-the-badge&labelColor=101418&color=b9c8da)
![GitHub repo size](https://img.shields.io/github/repo-size/jutraim/sitka-shell?style=for-the-badge&labelColor=101418&color=d3bfe6)

</div>


> A **Quickshell-based desktop environment** forked from [Niri Caelestia Shell](https://github.com/jutraim/niri-caelestia-shell)->[Caelestia Shell](https://github.com/caelestia-shell/caelestia-shell), adapted to run with the **Niri window manager**.
> This fork keeps the dashboard-based workflow while experimenting with new sidebar features and Niri.

<div align=center>



</div>

> [!CAUTION]
> This is for fun and it's **STILL WORK IN PROGRESS.**
>
> This repo is a standalone shell, removing the "dots" management and CLI from the original Caelestia project.

---

## ✨ What’s Different in This Fork?
Tactical angular aesthetic fork of Caelestia Shell. Still an early WIP focued on Niri, support for both Hyprland and Niri ipc is in the works. 

---

## 📦 Dependencies

You need both runtime dependencies and development headers.

<br>

* All dependencies in plain text:
   * `quickshell-git networkmanager fish glibc qt6-declarative gcc-libs cava libcava aubio libpipewire lm-sensors ddcutil brightnessctl material-symbols caskaydia-cove-nerd grim swappy app2unit libqalculate`

<details><summary> <b> Detailed info about all dependencies </b></summary>

<div align=center>


#### Core Dependencies 🖥️

| Package | Usage |
|---|---|
| [`quickshell-git`](https://quickshell.outfoxxed.me) | Must be the git version |
| [`networkmanager`](https://networkmanager.dev) | Network management |
| [`fish`](https://github.com/fish-shell/fish-shell) | Terminal |
| `glibc` | C library (runtime dependency) |
| `qt6-declarative` | Qt components |
| `gcc-libs` | GCC runtime |

#### Audio & Visual 🎵

| Package | Usage |
|---|---|
| [`cava`](https://github.com/karlstav/cava) | Audio visualizer |
| [`libcava`](https://pipewire.org) | Visualizer backend |
| [`aubio`](https://github.com/aubio/aubio) | Beat detector |
| [`libpipewire`](https://pipewire.org) | Media backend |
| [`lm-sensors`](https://github.com/lm-sensors/lm-sensors) | System usage monitoring |
| [`ddcutil`](https://github.com/rockowitz/ddcutil) | Monitor brightness control |
| [`brightnessctl`](https://github.com/Hummer12007/brightnessctl) | Brightness control |

#### Fonts 🔣

| Package | Usage |
|---|---|
| [`material-symbols`](https://fonts.google.com/icons) | Icon font |
| [`caskaydia-cove-nerd`](https://www.nerdfonts.com/font-downloads) | Monospace font |

#### Screenshot & Utilities 🧰

| Package | Usage |
|---|---|
| [`grim`](https://gitlab.freedesktop.org/emersion/grim) | Screenshot tool |
| [`swappy`](https://github.com/jtheoof/swappy) | Screenshot annotation |
| [`app2unit`](https://github.com/Vladimir-csp/app2unit) | Launch apps |
| [`libqalculate`](https://github.com/Qalculate/libqalculate) | Calculator |

#### BUILD dependencies 🏗️

| Package | Usage |
|---|---|
| [`cmake`](https://cmake.org) | Build tool |
| [`ninja`](https://github.com/ninja-build/ninja) | 🥷 |

</div>


### Manual installation

To install the shell manually, install all dependencies and clone this repo to `$XDG_CONFIG_HOME/quickshell/sitka-shell`.
Then simply build and install using `cmake`.


</details>

---

## ⚡ Installation

### Manual Build

1. Install dependencies.
2. Clone the repo:

    ```sh
    cd $XDG_CONFIG_HOME/quickshell
    git clone https://github.com/sitka-shell/sitka-shell
    ```
3. Build:

    ```sh
    nix build
    ```

### 🔃 Updating
You can update by running `git pull` in `$XDG_CONFIG_HOME/quickshell/sitka-shell`.

```sh
cd $XDG_CONFIG_HOME/quickshell/sitka-shell
git pull
```

<br>

---

## 🚀 Usage

The shell can be started via the `quickshell -c sitka-shell -n` command or `qs -c sitka-shell -n` on your preferred terminal.
><sub> (`qs` and `quickshell` are interchangable.) </sub>


* Example line for niri `config.kdl` to launch the shell at startup:

   ```
   spawn-at-startup "quickshell" "-c" "sitka-shell" "-n"
   ```

#### 🐧 Running on Non-NixOS Systems (Arch, Fedora, etc.)

Binaries built with Nix link against Nix store libraries, which can cause OpenGL/driver issues on other distros. To fix this, use the `arch` flake output, which wraps the shell with `nixGL`:

```sh
nix run github:sitka-shell/sitka-shell#arch --impure
```

*   Example line for niri `config.kdl` on Arch Linux:

    ```kdl
    spawn-at-startup "nix" "run" "github:sitka-shell/sitka-shell#arch" "--impure"
    ```

### 🛠️ Development Usage

To run the shell in development mode for testing changes without rebuilding the full package:

1. Enter the development shell to build dependencies and plugins: `nix develop`
2. Run: `qs -p ./`

This loads the config directly from the current directory. Ensure quickshell is installed on your system (e.g., `quickshell-git` on Arch Linux). The Sitka QML plugin and extras are built via Nix and made available.

Note: `nix run` builds and runs the packaged version automatically, handling all setup.

### Custom Shortcuts/IPC

All keybinds are accessible via [Quickshell IPC msg](https://quickshell.org/docs/v0.1.0/types/Quickshell.Io/IpcHandler/).

All IPC commands can be called via `quickshell -c sitka-shell ipc call ...`

* For example:

   ```sh
   qs -c sitka-shell ipc call mpris getActive <trackTitle>
   ```

* To lock the session:

   ```sh
   sitka-shell ipc call lock lock
   ```

* Example Niri keybind for locking:
    ```kdl
    binds {
        Mod+L { spawn "sitka-shell" "ipc" "call" "lock" "lock"; }
    }
    ```

* Example shortcut in `config.kdl` to toggle the launcher drawer:
    ```sh
    Mod+D { spawn  "qs" "-c" "sitka-shell" "ipc" "call" "drawers" "toggle" "launcher"; }
    ```

<br>

 The list of IPC commands can be shown via `qs -c shell ipc show`.

<br>

<details><summary> <b> Ipc Commands </b></summary>

  ```sh
  ❯ qs -c shell ipc show
  target picker
    function openFreeze(): void
    function open(): void
  target drawers
    function list(): string
    function toggle(drawer: string): void
  target lock
    function unlock(): void
    function isLocked(): bool
    function lock(): void
  target wallpaper
    function get(): string
    function set(path: string): void
    function list(): string
  target notifs
    function clear(): void
  target mpris
    function next(): void
    function previous(): void
    function getActive(prop: string): string
    function playPause(): void
    function pause(): void
    function stop(): void
    function list(): string
    function play(): void
  ```

</details>

---

## ⚙️ Configuration

Config lives in:

```
~/.config/sitka/shell.json
```
An example configuration file with comments is available at `config/shell.json.example`.
<details><summary> <b> Example JSON </b></summary>

```json
{
    "appearance": {
        "anim": {
            "durations": {
                "scale": 1
            }
        },
        "font": {
            "family": {
                "material": "Material Symbols Rounded",
                "mono": "CaskaydiaCove NF",
                "sans": "Rubik"
            },
            "size": {
                "scale": 1
            }
        },
        "padding": {
            "scale": 1
        },
        "rounding": {
            "scale": 1
        },
        "spacing": {
            "scale": 1
        },
        "transparency": {
            "enabled": false,
            "base": 0.85,
            "layers": 0.4
        }
    },
    "general": {
        "apps": {
            "terminal": [
                "foot"
            ],
            "audio": [
                "pavucontrol"
            ]
        }
    },
    "background": {
        "desktopClock": {
            "enabled": false
        },
        "enabled": true,
        "visualiser": {
            "enabled": true,
            "autoHide": true,
            "rounding": 1,
            "spacing": 1
        }
    },
    "bar": {
        "clock": {
            "showIcon": false
        },
        "dragThreshold": 20,
        "entries": [
            {
                "id": "logo",
                "enabled": true
            },
            {
                "id": "workspaces",
                "enabled": true
            },
            {
                "id": "spacer",
                "enabled": true
            },
            {
                "id": "activeWindow",
                "enabled": true
            },
            {
                "id": "spacer",
                "enabled": true
            },
            {
                "id": "tray",
                "enabled": true
            },
            {
                "id": "clock",
                "enabled": true
            },
            {
                "id": "statusIcons",
                "enabled": true
            },
            {
                "id": "power",
                "enabled": true
            },
            {
                "id": "idleInhibitor",
                "enabled": false
            }
        ],
        "persistent": false,
        "showOnHover": true,
        "status": {
            "showAudio": false,
            "showBattery": true,
            "showBluetooth": true,
            "showMicrophone": false,
            "showKbLayout": false,
            "showNetwork": true
        },
        "tray": {
            "background": true,
            "recolour": true
        },
        "workspaces": {
            "activeIndicator": true,
            "activeLabel": "󰮯",
            "activeTrail": false,
            "groupIconsByApp": true,
            "groupingRespectsLayout": true,
            "windowRighClickContext": true,
            "label": "◦",
            "occupiedBg": true,
            "occupiedLabel": "⊙",
            "showWindows": true,
            "shown": 4,
            "windowIconImage": true,
            "focusedWindowBlob": true,
            "windowIconGap": 0,
            "windowIconSize": 30
        }
    },
    "border": {
        "rounding": 25,
        "thickness": 10
    },
    "dashboard": {
        "mediaUpdateInterval": 500,
        "showOnHover": true
    },
    "launcher": {
        "actionPrefix": ">",
        "dragThreshold": 50,
        "vimKeybinds": false,
        "enableDangerousActions": false,
        "maxShown": 8,
        "maxWallpapers": 9,
        "specialPrefix": "@",
        "useFuzzy": {
            "apps": false,
            "actions": false,
            "schemes": false,
            "variants": false,
            "wallpapers": false
        },
        "showOnHover": false
    },
    "lock": {
        "recolourLogo": false
    },
    "notifs": {
        "actionOnClick": false,
        "clearThreshold": 0.3,
        "defaultExpireTimeout": 5000,
        "expandThreshold": 20,
        "expire": false
    },
    "osd": {
        "enabled": true,
        "enableBrightness": true,
        "enableMicrophone": true,
        "hideDelay": 2000
    },
    "paths": {
        "mediaGif": "root:/assets/bongocat.gif",
        "sessionGif": "root:/assets/kurukuru.gif",
        "wallpaperDir": "~/Pictures/Wallpapers"
    },
    "services": {
        "audioIncrement": 0.1,
        "defaultPlayer": "Spotify",
        "gpuType": "",
        "playerAliases": [
            {
                "from": "com.github.th_ch.youtube_music",
                "to": "YT Music"
            }
        ],
        "weatherLocation": "",
        "useFahrenheit": false,
        "useTwelveHourClock": false,
        "smartScheme": true,
        "visualiserBars": 45
    },
    "session": {
        "dragThreshold": 30,
        "vimKeybinds": false,
        "commands": {
            "logout": [
                "loginctl",
                "terminate-user",
                ""
            ],
            "shutdown": [
                "systemctl",
                "poweroff"
            ],
            "hibernate": [
                "systemctl",
                "hibernate"
            ],
            "reboot": [
                "systemctl",
                "reboot"
            ]
        }
    }
}

```

</details>

<details><summary> <b> Example Nix Home Manager </b></summary>

```nix
{
  programs.sitka-shell = {
    enable = true;
    settings.theme.accent = "#ffb86c";
  };
}
```

</details>

### 🎭 PFP/Wallpapers
The profile picture for the dashboard is read from the file `~/.face`, so to set
it you can copy your image to there or set it via the dashboard. **It's not a directory.**

The wallpapers for the wallpaper switcher are read from `~/Pictures/Wallpapers`
by default. To change it, change the wallpapers path in `~/.config/sitka/shell.json`.

To set the wallpaper, you can use the app launcher command `> wallpaper`.


---


## 🧪 Known Issues

1. Multi-monitor support is currently hardcoded :(
2. Task manager has no Intel GPU support.
3. Workspace bar needs refactoring at the moment.
4. Picker (screenshot tool) window grabbing is WIP due to Niri limitations.
5. Focus grabbing for Quickshell windows (power menu, task manager, settings) behaves awkwardly because of Niri limitations.
6. Quickshell may occasionally crash because of upstream issues (it re-opens automagically)

---

## 🙏 Credits



* [Quickshell](https://github.com/quickshell/quickshell) – Core shell framework

* [Caelestia](https://github.com/caelestia-shell/caelestia-shell) – Original project

* [Niri-Caelestia-Shell](https://github.com/0lxy/niri-caelestia-shell) - Inspiration for the Niri port

* [Niri](https://github.com/YaLTeR/niri) – Window manager backend

* All upstream contributors
