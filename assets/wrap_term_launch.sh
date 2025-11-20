#!/usr/bin/env sh

cat ~/.local/state/sitka/sequences.txt 2>/dev/null

exec "$@"
