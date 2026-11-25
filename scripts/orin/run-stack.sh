#!/usr/bin/env bash
# Start the rover stack from the latest good build, with the updater paused.
# Usage: run-stack.sh [ROS launch args]   e.g. run-stack.sh depth:=none
set -eo pipefail
WS="${KRATOS_WS:-$HOME/kratos_ws}"
REPO="${KRATOS_REPO:-$WS/src/kratos-rover}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f $WS/current/install/setup.bash ]] || { echo "no build at $WS/current (run rover-update.sh)" >&2; exit 1; }
"$HERE/updater-pause.sh" pause $$
trap '"$HERE/updater-pause.sh" resume' EXIT
# Auto_nav2/bringup.sh sources $KRATOS_BARE_INSTALL/setup.bash and the GLIM overlays itself.
# Note: the Auto_Cams packages (kratos_msgs, kratos_cameras) are in the same install.
KRATOS_BARE_INSTALL="$WS/current/install" "$REPO/Auto_nav2/bringup.sh" "$@"
