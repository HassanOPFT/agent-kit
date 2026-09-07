---
name: run-backend
description: >-
  Starts noon2_core locally with ./gradlew bootRun (ACTIVE_PROFILES=local,
  PORT=8082) after docker-deps, atlas-sync, and auth-port-forward are ready.
  Use when the user asks to run the backend, boot noon2_core, or serve the API
  for local frontend at http://localhost:8082/noon2-core. Skips start if already listening.
---

# Run backend (check-then-run)

**Scope:** lives in `agent-config` (local workspace / `local-custom`). Do **not**
copy into shared `noon2_core` `AGENTS.md` or commit under noon2_core `.claude/`.

Start noon2_core on the host with Gradle. Prefer this path over Docker app
containers. Do **not** use `../local-custom/start-noon2-core.sh` by default — it
tears down and recreates stacks (optional docker-app path only, with user OK).

**Port:** `PORT=8082` so facilitator / local FE (`noonConfig.local`) can call
`http://localhost:8082/noon2-core`. Pair FE with skill **run-frontend**
(`environment=local`); plain `yarn web` defaults to **dev**, not this BE.

**Never print** `.env` secrets. Load env privately if needed; do not `cat` or `echo` secret values.

**Host JVM hosts:** `noon2_core/.env` must use `localhost` (not Docker DNS /
`host.docker.internal`). Source of truth table: `../local-custom/HOST_BOOTRUN.md`
(aligned with IntelliJ **Noon2Application** env).

## Paths

| Item | Path / value |
| --- | --- |
| Repo root | noon2_core (has `./gradlew`) |
| Profile | `ACTIVE_PROFILES=local` |
| Port | `PORT=8082` |
| Health / base | `http://localhost:8082/actuator/health` · API base `http://localhost:8082/noon2-core` |

## 1. Prerequisites (other skills)

Run these in order. Each skill is check-then-run; skip work that is already ready.

1. **docker-deps** — MySQL (and other deps) healthy
2. **atlas-sync** — dry-run clean or schema applied
3. **auth-port-forward** — auth UP on `8771`

Stop if any prerequisite fails; report that skill's closing line and next action.

## 2. Check if already running

```bash
lsof -Pi :8082 -sTCP:LISTEN -t >/dev/null 2>&1 && LISTENING=1 || LISTENING=0
```

Optional confirm it is Noon2:

```bash
# Prefer process / log cues over dumping env
pgrep -fl Noon2Application || pgrep -fl bootRun || true
```

**If port 8082 is already serving noon2_core:** report
`run-backend: already running — http://localhost:8082/noon2-core` and stop.
Do not start a second instance.

## 3. Run

From noon2_core root (load `.env` into the process environment without printing it):

```bash
cd "$(git rev-parse --show-toplevel)"
set -a
# shellcheck disable=SC1091
[ -f .env ] && . ./.env
set +a
export ACTIVE_PROFILES=local
export PORT=8082
# Prefer .env already aligned for host (see ../local-custom/HOST_BOOTRUN.md).
# Belt-and-suspenders if .env still has Docker DNS:
export NOON2AUTH_HOST=http://localhost
export DB_HOST=localhost
./gradlew bootRun
```

Run in the background when the user needs the shell free; keep logs available.

Wait until the app is up (actuator health or log line that the server started).

## 4. Optional docker-app path (not default)

Only if the user explicitly wants the Dockerized app container:

- `../local-custom/start-noon2-core.sh` or `docker/noon2-core-docker-compose.yaml`
- Warn that this may stop/recreate containers

## 5. Failures → next action

| Failure | Next action |
| --- | --- |
| Deps / schema / auth not ready | Fix the failing prerequisite skill first |
| Port 8082 busy (not Noon2) | Free the port or choose another `PORT` and update FE config |
| Gradle / Java errors | Confirm Java 25; fix compile errors; re-run `bootRun` |
| Auth connection errors at runtime | Re-run **auth-port-forward** (prefer **persistent** kubectl if one-shot drops); confirm `NOON2AUTH_HOST=http://127.0.0.1` (not `host.docker.internal`) |
| `Failed to fetch google tokens` + `host.docker.internal` in logs | Restart with `NOON2AUTH_HOST=http://127.0.0.1`; auth must be UP on `:8771` |

## Closing line

`run-backend: already running — http://localhost:8082/noon2-core`  
or `run-backend: started — http://localhost:8082/noon2-core`  
or `run-backend: failed — <reason>`
