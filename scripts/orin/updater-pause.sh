#!/usr/bin/env bash
# Pause/resume the Orin auto-updater (rover-update.sh).
# Called by bringup while the stack runs, so the timer doesn't add load.
# The flag stores the owner PID; if that process dies (crashed bringup),
# the updater treats the flag as stale and resumes on its own.
#
#   updater-pause.sh pause [PID]   # PID defaults to the caller's parent
#   updater-pause.sh resume
#   updater-pause.sh status
FLAG="${KRATOS_UPDATER_FLAG:-/tmp/kratos-updater.paused}"   # /tmp: cleared on reboot

case "${1:-status}" in
  pause)  echo "${2:-$PPID}" > "$FLAG"; echo "updater paused (owner pid $(cat "$FLAG"))" ;;
  resume) rm -f "$FLAG"; echo "updater resumed" ;;
  status)
    if [[ -f $FLAG ]] && kill -0 "$(cat "$FLAG")" 2>/dev/null; then
      echo "paused (pid $(cat "$FLAG"))"; exit 0
    fi
    echo "active"; exit 1 ;;
  *) echo "usage: $0 {pause [pid]|resume|status}" >&2; exit 2 ;;
esac
