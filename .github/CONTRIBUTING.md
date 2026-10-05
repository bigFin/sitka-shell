# Contributing

Sitka Shell is an experimental personal shell, so discuss large behavioral or
visual changes before investing in them.

For focused fixes:

1. Keep the change scoped to one problem.
2. Follow the surrounding QML and C++ style.
3. Do not commit personal configuration, logs, crash dumps, or build output.
4. Run `node --test tests/*.test.mjs` (also checked by CI), then
   `nix build .#sitka-shell`.
5. Describe user-visible changes, compatibility impact, and validation in the
   pull request.

The Node suite always runs the dependency-free regressions. It also runs isolated
Qt keyboard/idle checks when Qt 6 `qmltestrunner` is on `PATH`; otherwise those
two checks report a skip. Set `QMLTESTRUNNER` to an executable path and, if needed,
`QML_IMPORT_PATH` to the Qt QML module directory to enable them. These tests use
offscreen rendering and stub actions, not the live desktop or system controls.

Commit subjects should be short and imperative. A conventional prefix such as
`fix:`, `feat:`, `docs:`, or `chore:` is preferred.
