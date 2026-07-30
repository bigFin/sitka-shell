# Sitka Shell Roadmap

## Current priorities

- Make screen ownership and drawer placement reliable on multi-monitor setups.
- Refactor the workspace bar around the current Niri window/workspace models.
- Replace the Hyprland-specific area-picker window matching with the
  compositor-neutral `WMService` API.
- Improve focus and keyboard dismissal for layer-shell windows such as the
  launcher, power menu, task manager, and settings.
- Add Intel GPU metrics without reintroducing unconditional background polling.

## Later

- Add Niri equivalents for the remaining compositor-specific window actions.
- Revisit dashboard window controls and content overflow.
- Make media/session decoration image cycling configurable.
- Continue simplifying old compatibility properties as configurations migrate.

## Project boundaries

- Configuration stays declarative through `shell.json` or Home Manager.
- Personal configuration, crash dumps, logs, and generated build output do not
  belong in the repository.
- The removed `caelestia-cli` theme and dots-management workflows are not
  planned to return.
- Hyprland compatibility is welcome when it fits the shared service layer, but
  Niri remains the primary target.
