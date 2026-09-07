---
name: docker-deps
description: >-
  Ensures noon2_core local Docker Compose dependencies (MySQL, Redis, MongoDB,
  Kafka, etcd, LocalStack) are running and healthy. Use when starting the
  backend, applying Atlas schema, or when local DB/cache/broker services are
  down. Checks first and starts only what is missing.
---

# Docker deps (check-then-run)

Ensure local dependency containers are up. Do **not** tear down healthy stacks.
Do **not** run `../local-custom/start-noon2-core.sh` (it stops and recreates deps).

## Paths

From **noon2_core** repo root:

| Item | Path |
| --- | --- |
| Compose file | `../local-custom/docker-compose.deps.yaml` |
| Fallback compose | `docker/deps-docker-compose.yaml` (use only if local-custom is missing) |

Key container names: `mysql`, `redis`, `mongodb`, `kafka`, `etcd`, `localstack`.

## 1. Check

```bash
# Docker daemon
docker info >/dev/null 2>&1 || { echo "NEXT: start Docker Desktop, then re-run docker-deps"; exit 1; }

COMPOSE="../local-custom/docker-compose.deps.yaml"
# Prefer local-custom; fall back if absent
[ -f "$COMPOSE" ] || COMPOSE="docker/deps-docker-compose.yaml"

docker compose -f "$COMPOSE" ps
```

Ready when:

- `mysql` is running (required)
- `redis`, `mongodb`, `kafka`, `etcd` are running when listed in the compose file

Optional quick probe (mysql):

```bash
docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' mysql
```

Expect `healthy` or `running`. Do not print `.env` or credential values in chat.

**If already ready:** report `docker-deps: ready` and stop. Do not restart.

## 2. Run (only if not ready)

```bash
cd "$(git rev-parse --show-toplevel)"
COMPOSE="../local-custom/docker-compose.deps.yaml"
[ -f "$COMPOSE" ] || COMPOSE="docker/deps-docker-compose.yaml"
docker compose -f "$COMPOSE" up -d
```

Wait until `mysql` is healthy (`docker inspect` health status) for up to ~60s.

## 3. Failures → next action

| Failure | Next action |
| --- | --- |
| Docker daemon down | Start Docker Desktop; re-run this skill |
| Compose file missing | Confirm `../local-custom` is checked out beside `noon2_core` |
| Container exits | `docker compose -f <compose> logs <service>`; fix and `up -d` again |
| Port conflict | Free the host port or stop the conflicting process; do not `down` a healthy stack without user OK |

## Closing line

`docker-deps: ready` or `docker-deps: started` or `docker-deps: failed — <reason>`
