# Dashboard keyboard controls

When the dashboard is opened explicitly (for example, with its configured
shortcut), focus moves to its wrapper. While that wrapper owns focus, press
**Space** or **Enter** to expand/collapse it. Holding a key does not repeatedly
toggle it. **Escape** closes and collapses the dashboard, including when an
unhandled Escape comes from a child control.

Use **Tab** to reach controls and the tab buttons' normal arrow/Space behavior
to select Dashboard, Media, Performance, Niri, or Usage. A focused tab receives
a stronger highlight. Enter/Space in a child control does not toggle the
whole dashboard. Mouse click, hover, and wheel selection remain available.

Hover previews and brief dashboard flashes caused by window-focus changes are
passive: they do not request compositor keyboard focus. An explicit shortcut or
header click acquires it; a shortcut promotes an existing preview instead of
closing it. Hovering away does not dismiss an explicitly opened dashboard.

Only one monitor owns drawer keyboard input at a time. Explicitly opening a
drawer on another monitor releases the old monitor's keyboard ownership without
closing its visible content. Hover alone cannot reclaim that ownership.

The compact dashboard uses an em dash for unavailable readings and labels stale
last-good data instead of presenting it as current. Actual zero remains zero.
Audio reports muted/unavailable separately. Set `dashboard.showUtc` to `true`
to add UTC beside the local clock; it defaults to `false`.

Media position updates and procedural/image decorations pause when their pane is
inactive, then resume without unloading the persistent pane. This does not stop
all media/audio services or establish whole-shell CPU/GPU savings.

Focus acquisition and dismissal still need checking on the live compositor.
Suggested manual check: open by shortcut, expand with Space/Enter, select a tab,
then press Escape. Change active windows and verify passive flashes do not
interrupt typing. On two monitors, explicitly open a drawer on each in turn and
verify keyboard input follows the most recent explicit request.
