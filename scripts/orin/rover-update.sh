#!/usr/bin/env bash
# Orin updater. Polls origin/main; on change: fast-forward, build into a fresh
# per-commit install dir, and only on success repoint ~/kratos_ws/current.
# Never restarts the running stack. Skips entirely while paused.
set -euo pipefail

REPO="${KRATOS_REPO:-$HOME/kratos_ws/src/kratos-rover}"
WS="${KRATOS_WS:-$HOME/kratos_ws}"
BUILDS="$WS/builds"
KEEP="${KRATOS_KEEP_BUILDS:-3}"
WORKERS="${KRATOS_BUILD_WORKERS:-2}"       # keep load on the Orin low
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log() { echo "[$(date -Is)] $*"; }

if "$HERE/updater-pause.sh" status >/dev/null; then log "paused; skipping"; exit 0; fi
exec 9>/tmp/kratos-updater.lock; flock -n 9 || { log "already running"; exit 0; }

cd "$REPO"
[[ "$(git rev-parse --abbrev-ref HEAD)" == main ]] || { log "not on main; skipping"; exit 0; }
mkdir -p "$BUILDS"

old=$(git rev-parse HEAD)
remote=$(git ls-remote origin refs/heads/main | cut -f1)
[[ "$remote" == "$old" ]] && exit 0
[[ -f "$BUILDS/.failed" && "$(cat "$BUILDS/.failed")" == "$remote" ]] && { log "$remote already failed; skipping"; exit 0; }

git fetch origin main
git merge --ff-only origin/main
git submodule update --init --recursive
new=$(git rev-parse --short HEAD)
dest="$BUILDS/$new"

rollback_src() { git reset --keep "$old" && git submodule update --init --recursive; }

log "building $new into $dest"
set +e
(
  source /opt/ros/"${ROS_DISTRO:-jazzy}"/setup.bash
  nice -n 10 colcon build \
    --base-paths "$REPO" \
    --build-base "$dest/build" --install-base "$dest/install" \
    --parallel-workers "$WORKERS" --symlink-install \
    --cmake-args -DROS_EDITION=ROS2 -DDISTRO_ROS="${ROS_DISTRO:-jazzy}" -DCMAKE_BUILD_TYPE=Release
) > "$BUILDS/$new.log" 2>&1
rc=$?
set -e

if [[ $rc -ne 0 ]]; then
  log "BUILD FAILED ($BUILDS/$new.log); staying on $(git rev-parse --short "$old")"
  echo "$remote" > "$BUILDS/.failed"
  rm -rf "$dest"; rollback_src; exit 1
fi

# Swap: previous <- current <- new (atomic symlink replace)
if [[ -L "$WS/current" ]]; then ln -sfn "$(readlink -f "$WS/current")" "$WS/previous"; fi
ln -sfn "$dest" "$WS/current.tmp" && mv -T "$WS/current.tmp" "$WS/current"
rm -f "$BUILDS/.failed"
log "current -> $new. Restart the stack when safe (no auto-restart)."

# Prune old builds, never current/previous
ls -1dt "$BUILDS"/*/ 2>/dev/null | tail -n +$((KEEP+1)) | while read -r d; do
  d=${d%/}
  [[ "$d" == "$(readlink -f "$WS/current")" || "$d" == "$(readlink -f "$WS/previous" 2>/dev/null)" ]] || rm -rf "$d"
done
