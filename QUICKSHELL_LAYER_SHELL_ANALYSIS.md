# Quickshell Layer Shell & Exclusion Analysis

This document details the implementation of the `wlr-layer-shell` protocol in `sitka-shell` (Quickshell) and how it affects the desktop environment, specifically regarding the crash loop observed with "papertoy".

## 1. Architecture Overview

`sitka-shell` uses a unique split-architecture for its main interface window and its desktop space reservation (exclusion zone).

*   **Main Window (`Drawers.qml`):**
    *   A single transparent Layer Shell surface that covers the **entire screen** (`anchors.fill: true`).
    *   Contains the Bar, Drawers, Dashboard, and other floating UI elements.
    *   **Exclusion Mode:** `ExclusionMode.Ignore`. This window does *not* reserve any space on the desktop. It sits on top of the wallpaper/desktop layer but lets windows flow under it (except where `input-region` is defined).

*   **Exclusion Window (`Exclusions.qml`):**
    *   Separate, invisible Layer Shell surfaces instantiated specifically to reserve space.
    *   **Dimensions:** `implicitWidth: 1`, `implicitHeight: 1`.
    *   **Mask:** `Region {}` (empty). This makes the window invisible and transparent to input.
    *   **Exclusion Zone:** Sets `exclusiveZone` to match the calculated width of the Bar (from `BarWrapper.qml`).

## 2. The Crash/Restart Loop

When `quickshell` crashes (e.g., due to the PipeWire issue resolved in this session) and subsequently restarts, the following sequence occurs on the Wayland protocol level:

1.  **Crash Event:** The `quickshell` process terminates.
2.  **Surface Destruction:** The Wayland compositor destroys all surfaces owned by the client:
    *   The Main Window (Visuals).
    *   The Exclusion Window (Space Reservation).
3.  **Desktop Expansion:**
    *   The removal of the Exclusion Window triggers a layout recalculation by the compositor.
    *   The "usable area" for the desktop (and background apps like Papertoy) expands to the full screen size (e.g., `width + bar_width`).
    *   **Event:** `zwlr_layer_surface_v1.configure` is sent to other clients (like Papertoy) with the new, larger dimensions.
4.  **Restart Event:** `quickshell` is automatically restarted by systemd or a script.
5.  **Surface Recreation:**
    *   `quickshell` initializes and creates the Main Window.
    *   `quickshell` creates the Exclusion Window.
6.  **Desktop Contraction:**
    *   The new Exclusion Window registers an `exclusive_zone` (e.g., 48px or similar).
    *   The compositor recalculates the layout.
    *   The "usable area" shrinks back to its original size.
    *   **Event:** `zwlr_layer_surface_v1.configure` is sent to other clients with the smaller dimensions.

## 3. Impact on Papertoy

The rapid sequence of **Expand -> Shrink** happens within milliseconds of the restart.

*   **Hypothesis:** Papertoy is crashing because it cannot handle this rapid double-resize event.
*   **Specific Failure Modes:**
    *   **Buffer Race:** Papertoy might be allocating a buffer for the "Expanded" size, but before it can commit it, it receives the "Shrink" event, leading to a size mismatch or invalid memory access.
    *   **Resource Exhaustion:** Repeatedly recreating EGL surfaces or context resources in a tight loop might be failing.
    *   **Uninitialized State:** If Papertoy relies on the exclusion zone being stable at startup, the temporary expansion might put it into an undefined state.

## 4. Resolution

The primary fix applied to `sitka-shell` (preventing the PipeWire crash) stops this cycle at step 1. By keeping `quickshell` stable, the Exclusion Window remains persistent, and the desktop area never fluctuates, preventing the crash trigger in Papertoy.

For **Papertoy development**, you should investigate its handling of `zwlr_layer_surface_v1.configure` events. Ensure it:
1.  Debounces resize requests if necessary.
2.  Gracefully handles receiving a new configure event while still processing a previous one.
3.  Does not assume a static `exclusive_zone` geometry.
