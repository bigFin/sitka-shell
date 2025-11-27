# Devlog

## 2025-11-27

### Buttress & Drawer Artifacts Investigation

**Status:** Ongoing
**Current Focus:** resolving "persistent squares" and "incorrect orientation" and "drawing over top".

**History:**
1.  **Issue:** Persistent square artifacts; Buttress orientation "interior".
2.  **Attempt 1 (Sync):** Failed.
3.  **Attempt 2 (Shape):** Failed.
4.  **Attempt 3 (Shape + Visible):** Failed.

**New Findings/Hypothesis:**
1.  **"Drawing over top":**
    - User reports Buttress draws *over* the left bar.
    - This implies `Buttress` (attached to Drawer) has a higher Z-index than the Bar, and physically overlaps it.
    - If `anchors.right: parent.left` (Drawer Left), and Drawer is adjacent to Bar, the Buttress (width > 0) extends *into* the Bar's space.
    - Overlap + Higher Z-index = Obscures Bar.

2.  **"Persistent Squares":**
    - Even with `visible: width > 1` and `Shape`, user sees squares.
    - This suggests either:
        - `width` is not reaching 0.
        - There is *another* component creating the square (e.g., a background in `Background.qml` or `Wrapper.qml` that I missed).
        - The "Square" is the Buttress itself rendering fully rectangular despite the Path (unlikely with Shape, unless Path is wrong).

3.  **"Interior to the drawer":**
    - User says they are "interior".
    - If the Drawer is translucent or has a border, and the Buttress is opaque?
    - Or maybe "interior" means the shape is inverted?
    - If I draw `\` (Top-Left to Bottom-Right), it cuts *away* the top-left corner of the rectangular bounding box.
    - If the user expects `/` (Bottom-Left to Top-Right) to flair *out* to the bar?

**Next Steps:**
1.  **Investigate Z-Order:** Check `modules/drawers/Drawers.qml` and `modules/bar/BarWrapper.qml` to see relative layering.
2.  **Investigate Buttress Color/Style:** Ensure it matches the Bar/Drawer correctly.
3.  **Debug Logs:** Add logging to `Buttress.qml` to track its lifecycle, width, and visibility.
4.  **Verify Orientation:** Re-evaluate the `orientation` logic.