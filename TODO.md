# Sitka Shell To-Do & Roadmap

## 🚧 Immediate Refactor Follow-ups
The following features were disabled during the removal of `caelestia-cli`. They need to be re-implemented or removed to align with the new declarative philosophy.

- **Wallpaper Management**
  - [ ] `services/Wallpapers.qml`: `setWallpaper` is disabled.
  - [ ] `services/Wallpapers.qml`: Preview color generation (`getPreviewColoursProc`) is disabled.
  - [ ] `modules/launcher/services/Actions.qml`: "Random Wallpaper" action is disabled.

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


some minor nit picks/style issues
  - Top HUD theme is inapropriately applied, review and propose improved suggestions to user if the solution is not clear.

  

  We need to replace the kawaii kitty in the top HUD with the images i have put in ./config/images.  same with the anime lady graphic in the power drawer. 


We should make the nixos operating system icon that's in the top left of the main bar, clicking that should open the app launcher

The left main bar theme seems like the active workspace color is off for the theme, if its obvious to you fix it (rn its red on everforest light), or we can collaboratively track down the correct var.
