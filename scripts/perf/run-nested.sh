#!/usr/bin/env bash
# NixOS + Xvfb/Niri. Usage: run-nested.sh FROZEN_TREE NEW_EVIDENCE_DIR [options]
set -euo pipefail
if (($# < 2)); then printf 'Usage: %s FROZEN_TREE NEW_EVIDENCE_DIR [--runs N] [--idle-seconds S]\n' "$0" >&2; exit 2; fi
scripts=$(cd -- "$(dirname -- "$0")" && pwd -P)
source=$(realpath -- "$1"); dest=$(realpath -m -- "$2"); shift 2
[[ $dest != "$source" && $dest != "$source/"* ]] || exit 2
manifest=$(dirname -- "$source")/baseline.sha256
expected=636da5d5b3bbc0ae8f7426a3f06b22e41429a48c15f8359b8481efcbc21e42fd
[[ $(sha256sum "$manifest" | cut -d' ' -f1) == "$expected" ]] || { printf 'Wrong source manifest\n' >&2; exit 1; }
(cd "$source"; sha256sum --quiet -c "$manifest"; python3 - "$manifest" <<'PY'
from pathlib import Path
import sys
expected = {s.split('  ./', 1)[1] for s in Path(sys.argv[1]).read_text().splitlines()}
actual = {str(p) for p in Path('.').rglob('*') if p.is_file() or p.is_symlink()}
if actual != expected: raise SystemExit(f'Unexpected source inventory: {actual ^ expected}')
PY
)
mkdir -p -- "$(dirname -- "$dest")"; mkdir -m 700 -- "$dest"
cp -- "$manifest" "$dest/baseline.sha256"
printf '%s\n' "$source" > "$dest/source-path.txt"
sha256sum -- "$scripts"/*.py "$scripts/run-nested.sh" > "$dest/runner.sha256"
libs=(); for so in libXcursor.so.1 libXrandr.so.2 libXi.so.6 libX11.so.6 libxkbcommon.so.0 libxkbcommon-x11.so.0 libXinerama.so.1 libXxf86vm.so.1 libGL.so.1; do
    for f in /nix/store/*/lib/"$so"; do [[ -e $f ]] && { libs+=("${f%/*}"); break; }; done
done
BENCH_NIRI_LIBS="$(IFS=:; printf '%s' "${libs[*]}"):/run/opengl-driver/lib"
export BENCH_NIRI_LIBS
if ! BENCH_XDOTOOL=$(command -v xdotool); then for f in /nix/store/*-xdotool-*/bin/xdotool; do [[ -x $f ]] && { BENCH_XDOTOOL=$f; break; }; done; fi
export BENCH_XDOTOOL; [[ -x $BENCH_XDOTOOL ]]
cd -- "$source"
# The benchmark has no host PID/network/IPC namespaces, session sockets, real
# home, graphics devices or writable system mounts. Namespace init kills strays.
exec nix develop --no-write-lock-file path:. -c bwrap --unshare-all --die-with-parent --new-session \
  --ro-bind /nix/store /nix/store --ro-bind /bin /bin --ro-bind /usr/bin /usr/bin \
  --ro-bind /etc /etc --ro-bind /run/current-system /run/current-system --ro-bind /run/opengl-driver /run/opengl-driver \
  --ro-bind /sys /sys --proc /proc --dev /dev --tmpfs /tmp --dir /tmp/.X11-unix \
  --ro-bind "$source" /frozen --ro-bind "$scripts" /bench --bind "$dest" /evidence --chdir /frozen \
  python3 -I -B /bench/nested.py "$@"
