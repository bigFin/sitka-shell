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


in the left bar, there is an active window display that when you hover over it, it pops out a detail about the active window. And you can click on that to open up the performance monitor. But that active window pop out that comes up whenever you hover over the active window title on the left bar. It has two square chunks cut out of the left top and bottom where it joins the left bar, where instead I would expect it to have a chamfer similar to the top of the top of the head's up display. Actually, all of the left bar pop out drawers have this issue. 


We should make the NYX operating system icon that's in the top left of the main bar, clicking that should open the app launcher


The app launcher drawer on the bottom has a transparent background. It should be opaque.
