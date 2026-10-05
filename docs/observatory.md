# Observatory

An opt-in dark theme: ocean ink, warm phosphor text, amber instruments,
sea-glass secondary actions and workstation violet. The bar keeps its existing
layout and controls; a fine rail edge and clock rule give it a quiet instrument
panel hierarchy. Fonts remain your configured fonts (Iosevka Term by default).

## Activate

Merge the keys from `config/presets/observatory.json` into your existing
`$SITKA_CONFIG_DIR/shell.json` (normally `~/.config/sitka/shell.json`). Do not
replace a populated configuration: the preset contains only the theme and
opaque surfaces. If you have no configuration, it can serve as your initial
`shell.json`. No restart is needed; Sitka watches that file.

These commands require a running version that includes Observatory; editing this
checkout does not update an older installed shell. For a temporary preview on
an updated packaged instance:

```sh
sitka-ipc call theme set Observatory
sitka-ipc call theme reset
```

For checkout runs, use `qs -p /path/to/sitka-shell ipc` instead of `sitka-ipc`.
Use the same path as your running instance. `theme list`
includes Observatory. Reset clears the temporary override and restores the
configured theme; it does not undo a change to `shell.json`.

## Wallpaper

`assets/wallpapers/observatory.svg` is an original static 3840 × 2160 vector
chart. Pressure-like contours and an oblique orbital plane occupy the right
field, leaving the left side quiet. Its geometry is artwork, not weather data
or satellite telemetry. It has no scripts, external resources or animation.

Copy it to your wallpaper directory and select it using the existing wallpaper
picker, or pass its **absolute path** to your running shell:

```sh
sitka-ipc call wallpaper set /absolute/path/to/observatory.svg
```

The wallpaper is deliberately separate from the preset: there is no portable
absolute asset path and applying a theme should not replace your wallpaper.
SVG rendering requires the Qt SVG image plugin. If unavailable, export the SVG
to PNG in an image editor and select that instead. The composition tolerates
cropping; the complete orbital field is best on a landscape display.

## Palette and limits

All M3 roles, fixed colors, terminal colors and compatibility accents have
explicit Observatory values. Its palette is separate from the legacy palette,
so switching away does not leave Observatory colors behind. Existing themes
keep their previous mappings, including their inherited M3 defaults.

Opaque text/background role pairs are regression-tested for WCAG contrast of
at least 4.5:1; outline contrast is tested separately. This is not a full UI
accessibility certification. Transparent modes remain available, but wallpaper
compositing changes contrast, so the preset opts into opaque surfaces. No
shader, animation loop, font download, bar behavior or telemetry is added.
