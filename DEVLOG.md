# Devlog

## 2025-11-27

### Buttress & Drawer Artifacts Investigation

**Status:** Ongoing
**Current Focus:** Debugging persistent square artifacts and incorrect orientation of Buttress components.

**History:**
1.  **Issue Reported:** "Small square artifacts" left after drawer collapse, and buttresses "incorrectly orientated" (interior to drawer).
2.  **Hypothesis 1 (Failed):** Race condition between `Buttress` internal animation and `Wrapper` size animation.
    - **Action:** Refactored `Buttress.qml` to remove internal state/animation. Bound `Buttress.width` directly to a new synchronized `wrapper.buttressSize` property in all wrappers (`bar`, `dashboard`, `launcher`).
    - **Result:** User reports no change. Squares persist, orientation still wrong.

**New Findings/Hypothesis:**
1.  **Persistent Squares:**
    - The "squares" might be caused by `Canvas` failing to clear/redraw correctly when `width` shrinks, or `visible` property not triggering fast enough.
    - Since `clearRect` uses the *current* `width`, shrinking the width means we assume the canvas clips or clears the rest. If Qt's `Canvas` implementation retains the backbuffer without clipping, the "old" larger drawing might remain visible if the frame isn't fully cleared.
    - Alternatively, the `buttressSize` property might not be animating all the way to 0, or the `visible` binding `width > 0` has a threshold issue.

2.  **Incorrect Orientation:**
    - User described them as "interior to the drawer".
    - Current `orientation: 0` (Top-Left) draws a triangle with points `(w,0)`, `(0,0)`, `(w,h)`.
        - Top edge: Horizontal.
        - Right edge: Vertical (Against drawer).
        - Left edge: Diagonal.
    - If the user sees this as "interior", perhaps the "Buttress" is rendering *over* the drawer (z-ordering?) or the shape logic creates a visual that implies a cutout.
    - If the intention is to "extend the opened drawer", it implies the shape should bridge the gap.
    - I need to verify what "orientation 0" actually produces visually vs what is expected.

**Next Steps:**
1.  **Research:** Use `codebase_investigator` to verify how `Buttress` is actually anchored and if there are Z-index issues.
2.  **Experiment:**
    - Force `Canvas` to clear the entire *previous* bounds before repainting, or use a simpler `Item` based shape (like `Shape` or `Rectangle` with rotation/clipping) to avoid Canvas rendering bugs.
    - Add debug logging to `Buttress.qml` to track `width` and `onPaint`.
    - Review the coordinate geometry in `Buttress.qml` carefully.