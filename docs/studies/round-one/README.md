# Observatory: three material studies

**Recommendation: take Mission Control and Sun Workstation to the next round.** Mission’s results bay gives the selection one unbroken line; its inspector makes the description available without asking the eye to skip eight descriptions. On the Monitor, bars on a common 0–100% scale make 82% storage visibly different from 21% memory. Sun is the useful counterexample: its violet selection and recessed result well read without any light emission. Keep Sun’s precise edges, not necessarily the full pale case. VFD produces the strongest individual numerals but lacks the bars’ direct length comparison; keep the smoked readout as a candidate component rather than promoting the whole terminal. These are visual judgments, not timed user-study results.

## What to review

Open **`../design-evidence/index.html`** from the design worktree. The gallery links one **`comparison-board.png`** and twelve pairs of full frames and native crops. The board’s large thumbnails preserve placement on the desktop; the separate 1:1 samples underneath are for inspecting selection, values and edge treatment. View the PNGs at 100% for pixel work. `frames/live-*` are unchanged QML captures. `frames/prototype-*` are browser renders; `prototypes/*.html` are the inert scene sources generated for inspection, not shell windows. No remote fonts, images, scripts, shell actions or running server are needed to review the evidence.

| Study | Command / Inspect | Monitor |
| --- | --- | --- |
| **A · Sun Workstation** | Ceramic body, raised title rail, recessed query/list, violet selection with a pointer. Descriptions stay under each result. | Ruled capacity ledger above a quieter date/system desk; the compact uses a small inset status strip. No bloom. |
| **B · Mission Control** | A wide two-bay assembly: short list at left, selected description and etched pictogram at right. Stipple belongs to the pictogram’s backplate, never to its glyph. | Fixed section rail, framed bar plot, separate unavailable readouts and docked key legend. One directional cast shadow under the assembly. |
| **C · VFD Terminal** | Matte two-column command register; name and description share a baseline. No glowing launcher text. | Smoked glass contains the live-value design treatment. Only valid numerical readings have localized bloom. Calendar, section labels, missing values and key legends do not. |

**Type and data.** TeX Gyre Heros sets the application names and UI hierarchy, offering a proportional comparison with the existing launcher. Iosevka Regular sets numerals, shortcuts and time. The same fixture is defined once in `scenes.py`: empty query; Accessibility selected; all eight visible apps in captured order; CPU and audio unavailable, memory 21%, storage 82%; Sunday, November 22, 2026 at 13:19; sunny, 12 °C; NixOS 26.11 (Zokor), niri, no media. Percentages are capacity readings, not thresholds or synthetic histories.

**Baseline limits.** The screenshots came from the isolated integrated-preview run, not a new capture falsely attributed to the branch tip. They show the same Observatory surfaces as the frozen source; the intervening DND change is not visible in these states. The live compact capture shows the active desktop/window title rather than the four measurements; all three proposals deliberately bring the expanded view’s readings forward. “Desktop → Desktop” is shortened to “Desktop,” time is set in 24-hour notation and the partially shown uptime is shortened to days/hours. Shell actions, decoration controls and inactive media transport are not simulated. Mission shows the selected description in its own bay instead of every description in the list. Source and screenshot digests are checked before rendering.

## Reproduce

Requirements: Chrome/Chromium with headless CDP, Python with Pillow and `websockets.sync`, `sha256sum`, Iosevka Regular, and regular/bold TeX Gyre Heros. The recorded run used Chrome 157.0.8103.78, Python 3.14.9, Pillow 13.0.0, websockets 15.0.1, Iosevka 34.7.0 and TeX Gyre 2.501. Unmodified font files and their notices are carried in the local generated evidence only. The script does not install anything, touch the active shell, or write into the frozen tree.

From the **design worktree root** on the reference machine:

```sh
python -B docs/studies/round-one/render.py \
  --captures ../../integrated-preview \
  --snapshot ../baseline --manifest ../baseline.sha256 \
  --out ../design-evidence \
  --mono /nix/store/gp6dsamq0i01xlc6n7ifiwmmlfqjmv7c-Iosevka-34.7.0/share/fonts/truetype/Iosevka-Regular.ttf \
  --ui "$(fc-match 'TeX Gyre Heros:style=Regular' -f '%{file}')" \
  --ui-bold "$(fc-match 'TeX Gyre Heros:style=Bold' -f '%{file}')"
```

Elsewhere, pass paths to the same inputs, choose a separate output directory, and pass `--browser chromium` if appropriate. The snapshot has public base `914f79c3e`; its SHA-256 manifest digest is `636da5d5b3bbc0ae8f7426a3f06b22e41429a48c15f8359b8481efcbc21e42fd`. That digest identifies the integrated comparison source, **not** the clean design branch HEAD.

`render-report.json` records the actual renderer version, font and image digests, native crop rectangles, viewport, loaded fonts, rendered text and panel bounds. Rendering checks the expected selection/order, values, calendar state, all twelve 1280 × 800 frames, and that desktop changes stay within the drawer and its shadow. Generated evidence stays outside this source directory. Round 1 does not test input, live collectors, fractional scaling, accessibility conformance, QML performance or deployment.
