# Development Log

## [2025-11-27] Crash Investigation & Stability Fixes

### Issue
- **Source**: Crash log from `/run/user/1000/quickshell/by-id/.../log.qslog`.
- **Symptoms**: Multiple `TypeError: Value is undefined` exceptions in QML files.
  - `Workspaces.qml`: Accessing `Niri.focusedWindow.id` when `focusedWindow` was undefined.
  - `DraggableWindowColumn.qml`: Accessing properties of undefined workspaces or out-of-bounds array indices for grouped windows.
  - `WindowDecorations.qml`: Accessing properties of `root.client` (the window) when it was null/undefined.

### Investigation & Reasoning
- **Root Cause**: The QML property bindings were too "eager" and did not account for transient states where the Niri service might return `null` or `undefined` (e.g., during window closing, workspace switching, or initialization).
- **Impact**: These unhandled TypeErrors caused the Quickshell instance to crash or behave erratically.

### Changes Applied
1.  **`modules/bar/components/workspaces/Workspaces.qml`**:
    - **Fix**: Added a null check for `Niri.focusedWindow` before accessing `.id`.
    - **Code**: `readonly property int focusedWindowId: Niri.focusedWindow ? Niri.focusedWindow.id : -1`

2.  **`modules/bar/components/workspaces/DraggableWindowColumn.qml`**:
    - **Fix 1 (Workspace)**: Added a guard check for `Niri.currentOutputWorkspaces[...]` to ensure the workspace exists before calling `getWindowsByWorkspaceId`.
    - **Fix 2 (Groups)**: Added a fallback object for `fullGroup` (`{ main: null, windows: [], count: 0, id: -1 }`) to prevent crashes if the `Repeater` index is temporarily out of sync with `groupedWindowsArray`.

3.  **`components/widgets/WindowDecorations.qml`**:
    - **Fix**: Applied optional chaining (`?.`) to all instances of `root.client` usage (e.g., `root.client?.is_floating`).

### Insights for Future Development
- **Defensive Coding in QML**: When binding to external services like `Niri`, always assume the object might be `null` or `undefined`.
- **Pattern**: Prefer optional chaining (`?.`) or ternary operators with safe defaults (e.g., `-1`, `false`) for properties derived from service state.
- **List Models**: Be wary of array indexing in `Repeater` delegates if the underlying model changes frequently; provide fallbacks or checks.

## [2025-11-27] Theming Inconsistency Fix

### Issue
- **Observation**: The Left Bar and Top Drawer (Dashboard) were rendered with inconsistent transparency compared to the Bottom Drawer (Launcher). The Launcher appeared opaque, while the others were partially transparent or lacked the correct opaque background layer.
- **Context**: The `Drawers.qml` file manages the overall window and layering for these components.

### Changes Applied
1.  **`modules/drawers/Drawers.qml`**:
    - **Fix**: Moved `Dashboard.Background` (Top Drawer) from the transparent `Backgrounds.qml` container into the `opaqueDrawerSurface` item. This ensures it shares the same opaque background rendering context as the `Launcher.Background`.
    - **Fix**: Moved the `Border` component (Left Bar border) out of the transparent container to the root level of the window, ensuring it is rendered opaquely.

2.  **`modules/drawers/Backgrounds.qml`**:
    - **Cleanup**: Removed `Dashboard.Background` and its import, as it is now instantiated in `Drawers.qml`.

### Result
- The Left Bar, Top Drawer, and Bottom Drawer now share a consistent opaque visual style, unifying the shell's appearance.
