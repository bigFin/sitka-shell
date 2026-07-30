# Contributing

Sitka Shell is an experimental personal shell, so discuss large behavioral or
visual changes before investing in them.

For focused fixes:

1. Keep the change scoped to one problem.
2. Follow the surrounding QML and C++ style.
3. Do not commit personal configuration, logs, crash dumps, or build output.
4. Run `nix build .#sitka-shell`.
5. Describe user-visible changes, compatibility impact, and validation in the
   pull request.

Commit subjects should be short and imperative. A conventional prefix such as
`fix:`, `feat:`, `docs:`, or `chore:` is preferred.
