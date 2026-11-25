#!/usr/bin/env bash
# One-time setup on the Orin: install and start the updater timer (user systemd).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p ~/.config/systemd/user
cp "$HERE"/systemd/rover-update.{service,timer} ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now rover-update.timer
# Keep user timers running when nobody is logged in
loginctl enable-linger "$USER" || echo "enable-linger failed; timer only runs while logged in"
systemctl --user list-timers rover-update.timer --no-pager
