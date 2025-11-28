# Devlog

## 2025-11-27

### Buttress & Drawer Artifacts Investigation

**Status:** Completed
**Focus:** Resolving rendering artifacts and orientation issues with Buttress components.

**Summary of Fixes:**
1.  **Persistent Square Artifacts:**
    - **Root Cause:** Un-filleted (square) corners of the drawer background (`StyledRect`) remained visible when the covering `Buttress` shrank to 0 width.
    - **Resolution:** Updated `Background.qml` files for Dashboard, Launcher, and Bar Popouts to strictly synchronize the entire background's visibility with `wrapper.buttressSize > 0.5`.

2.  **Closing Flash Artifacts:**
    - **Root Cause:** Sub-pixel rendering of the square corner before the visibility toggle kicked in.
    - **Resolution:** Increased visibility threshold from `> 0` to `> 0.5` to hide the drawer slightly earlier in the animation.

3.  **Rendering Quality:**
    - **Resolution:** Refactored `components/effects/Buttress.qml` from `Canvas` to `QtQuick.Shapes` to eliminate texture caching issues and improve performance.

4.  **Incorrect Orientation (Left Bar):**
    - **Root Cause:** Buttresses were anchored to the *side* of the drawer, but the visual goal was to ease the vertical transition.
    - **Resolution:** Re-anchored Top/Bottom buttresses to sit *above* and *below* the drawer respectively (`anchors.bottom: parent.top` / `anchors.top: parent.bottom`), creating a vertical fillet that bridges the app drawer edge to the left bar.

**Result:**
- Artifacts are gone.
- Orientation is correct (vertical easing).
- Animations are smooth without flashes.