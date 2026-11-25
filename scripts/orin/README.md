# Orin rolling-update tooling

Flow: child repo push to `main` -> `sync-submodules.yml` bumps `development` and opens a PR
-> CI passes and the author approves -> merged to `main` -> the Orin timer pulls and builds.

| Script | Purpose |
|---|---|
| `install.sh` | One-time: install/enable `rover-update.timer` (every 5 min) |
| `rover-update.sh` | Fast-forward `main`, build to `~/kratos_ws/builds/<sha>`, swap `~/kratos_ws/current` on success. Never restarts the stack |
| `run-stack.sh` | Pause updater, run `Auto_nav2/bringup.sh` from `current`, resume on exit |
| `updater-pause.sh` | `pause [pid]` / `resume` / `status`. Stale flag (dead owner pid) is ignored |
| `rover-rollback.sh` | Swap `current` and `previous`, then restart the stack |

Logs: `journalctl --user -u rover-update` and `~/kratos_ws/builds/<sha>.log`.
Env: `KRATOS_BUILD_WORKERS` (default 2), `KRATOS_KEEP_BUILDS` (3), `KRATOS_REPO`, `KRATOS_WS`.
