# Nested Observatory performance baseline

Measure a **manifest-verified frozen working copy**, not the fork checkout containing these scripts. No shell code is patched. This runner targets the NixOS host used for the study; it is not a general desktop benchmarking tool.

```sh
# From the perf checkout, with the frozen snapshot and baseline.sha256 next to it:
scripts/perf/run-nested.sh ../baseline ../perf-evidence/repeat --runs 4 --idle-seconds 6
python3 scripts/perf/summarize.py ../perf-evidence/repeat
```

Use a new evidence directory: the runner refuses to overwrite one. For a short gate, use `--runs 1 --idle-seconds 1` with a different directory. Every trial costs more than the idle windows alone: there are warm-up periods, control checks and seven interactive traces. Do not run another load test at the same time. The renderer/software stack, fixture contents and exact screen size matter.

## What runs

1. The wrapper checks the pinned SHA-256 of `baseline.sha256`, every listed hash, and the source file inventory. It enters the frozen tree’s Nix development shell using `path:.` to include non-Git source. Required host tools: Nix/flakes with the frozen inputs, Bubblewrap with working user namespaces, Niri/Winit, Xvfb, xdotool, glxinfo, grim, busctl, dbus-daemon and Python 3. The pinned dev shell supplies the Quickshell executable, Qt QML imports and Sitka plugin. The compositor alone receives additional X11 library paths.
2. Bubblewrap provides separate PID, IPC, mount and network namespaces, synthetic `/dev`, private `/tmp` and `/proc`. The fixture cannot see the host home or session/system sockets. The frozen tree, scripts, Nix store, system config and sysfs are read-only; the evidence directory and temporary fixture state are writable. Rootless Xvfb runs inside that private network and `/tmp`, with TCP disabled. A fresh non-activating D-Bus daemon admits only specified well-known names. The runner checks `ListActivatableNames` before starting the compositor, addresses the system bus at a nonexistent socket, and hands a short allowlist of environment variables to the fixture. **Do not use host key injection or fall back to the host session if this fails.**
3. Every trial launches its own Xvfb, Niri, shell and D-Bus; checks exactly one 1280×800 1× output and private focused Niri X window; then runs startup → closed → launcher first → close → reopen warm → close → compact dashboard → Space → expanded → Escape → returned. The shell's IPC confirms the wallpaper and dashboard states. The eight launcher entries have no-op executables; nothing is launched. `grim` takes a reference frame after, not during, each steady-state measurement.
4. The Xvfb framebuffer probe separately timestamps observed pixel changes. It does not use IPC readiness as a frame timestamp. `/proc` endpoints and two internal service-counter snapshots supply the steady-state evidence; the benchmark does not enable a profiler in the runtime. See `report.md` for precise boundaries, exclusions and base variability. A stalled shell, wrong display, missing visible change or unstable pre-action region fails the trial rather than inventing a latency.
5. The runner reaps its own process groups in reverse order and removes each temporary home/runtime. The outer process namespace additionally contains any detached descendants and dies with its parent. Incomplete cohorts lack `complete` and cannot be summarized. Raw JSON, timestamped samples, state PNGs, per-child logs and cleanup records survive outside the namespace. `summarize.py` emits four CSVs and `report.md` from a completed cohort; it requires only the Python standard library.

The all-effects-off condition is deliberately absent: the frozen configuration has individual dither/fillet/shader switches, not an Observatory master switch. Test any of those separately under its real name. Rendering at real hardware scanout, compositor presentation times, actual wakeups, short-lived child execs and energy require different instrumentation.
