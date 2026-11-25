#!/usr/bin/env bash
# Swap ~/kratos_ws/current and previous. Restart the stack afterwards.
set -euo pipefail
WS="${KRATOS_WS:-$HOME/kratos_ws}"
[[ -L "$WS/previous" ]] || { echo "no previous build" >&2; exit 1; }
cur=$(readlink -f "$WS/current"); prev=$(readlink -f "$WS/previous")
ln -sfn "$prev" "$WS/current.tmp" && mv -T "$WS/current.tmp" "$WS/current"
ln -sfn "$cur" "$WS/previous"
echo "current -> $(basename "$prev") (was $(basename "$cur")). Restart the stack."
