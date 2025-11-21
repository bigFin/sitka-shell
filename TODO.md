# Sitka Shell To-Do & Roadmap

## 🚧 Immediate Refactor Follow-ups
The following features were disabled during the removal of `caelestia-cli`. They need to be re-implemented or removed to align with the new declarative philosophy.

- **Wallpaper Management**
  - [ ] `services/Wallpapers.qml`: Preview color generation (`getPreviewColoursProc`) is disabled.

- **Theme/Scheme Management**
  - [ ] `modules/launcher/services/Schemes.qml`: Scheme listing and setting are disabled.
  - [ ] `modules/launcher/services/M3Variants.qml`: Variant setting is disabled.
  - [ ] `modules/launcher/services/Actions.qml`: "Light/Dark" mode actions need verification (currently call `Colours.setMode`, check if that relies on external state).

- **Configuration & State**
  - [ ] Verify `shell.json` is being watched/read correctly from `~/.config/sitka/shell.json`.
  - [ ] Decide if UI controls for changing settings (e.g. in the Launcher) should remain. If the shell is strictly declarative, these buttons should probably be removed to avoid user confusion.

## 🐛 Known Issues (Inherited)
- **Multi-monitor**: Support is currently hardcoded/limited.
- **Task Manager**: No Intel GPU support.
- **Niri Integration**:
  - Window decorations (pin/close/fullscreen) in Dashboard are missing.
  - Window grabbing for the "Picker" (screenshot) tool is WIP.
  - Focus grabbing for popups is awkward.

## 🔮 Future Goals
- [ ] **Declarative Config**: Ensure all "dynamic" state is moved to `shell.json` or managed via Nix `home-manager` options.
- [ ] **Niri Management Tab**: Redesign the experimental management tab in the dashboard.
- [ ] **Sidebar Rewrite**: The workspace bar needs a refactor.


the power drawer it too kawaii it needs to be angularized


The drawers on the left bar have some permamnently visible squares on the right edge of the bar, and they dont have a buttress when expanded. 


update readme, shouts out caelestia and niri-caelestia shell both 

is it feasible to make the top drawer hud and the right drawer hud both cycle through images (perhaps one dir per drawer to put img in) when you click on the image?
