# Sitka Shell Roadmap

## Current priorities

- Make screen ownership and drawer placement reliable on multi-monitor setups.
- Add keyboard dismissal for the dashboard (see the TODO in
  `modules/dashboard/Wrapper.qml`); launcher and session menu already
  dismiss with Escape.
- Add Intel GPU utilization if an unprivileged source appears. Temperature
  is already reported through hwmon; whole-GPU load still needs
  `intel_gpu_top` or perf counters, so `usage` stays null by design.

## Later

- Revisit dashboard window controls and content overflow (see the TODO in
  `modules/dashboard/ActiveWindow.qml`).
- Make media/session decoration image cycling configurable.
- Continue simplifying old compatibility properties as configurations migrate.

## Done

- Workspace bar runs on the Niri window/workspace models (`WorkspaceModel`,
  `WindowStore`, `WMService` throughout `modules/bar`).
- Area-picker client matching uses the compositor-neutral `WMService`
  API on Niri (`modules/areapicker/Picker.qml`); Hypr path kept as-is.
- Launcher and session menu dismiss with Escape and arrow-key navigation.

## Project boundaries

- Configuration stays declarative through `shell.json` or Home Manager.
- Personal configuration, crash dumps, logs, and generated build output do not
  belong in the repository.
- The removed `caelestia-cli` theme and dots-management workflows are not
  planned to return.
- Hyprland compatibility is welcome when it fits the shared service layer, but
  Niri remains the primary target.
