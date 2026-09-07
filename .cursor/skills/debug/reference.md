# Debug — noon reference

Load on demand from the `debug` skill. Paths are relative to the noon workspace root.

## Bug Agent context (canonical)

| Repo | Playbook | Service map | Architecture |
| --- | --- | --- | --- |
| Core | `noon2_core/.github/bug-agent/context/debugging-playbook.md` | `…/service-map.md` | `…/architecture.md` |
| Frontend | `noon2-frontend/.github/bug-agent/context/debugging-playbook.md` | `…/service-map.md` | `…/architecture.md` |

Also useful: `noon2_core/AGENTS.md`, `noon2-frontend/AGENTS.md`, `api-test-scripts/AGENTS.md`.

## Datadog services

### Backend (`env:` = `dev` \| `staging` \| `experimental` \| `prod`)

| Service | Use for |
| --- | --- |
| `noon2-core-http` | REST/API |
| `noon2-core-ws` | Live classroom / STOMP |
| `noon2-core-worker` | Jobs / async |

### Frontend RUM

| Service |
| --- |
| `noon2-student-web` / `noon2-student-native` |
| `noon2-teacher-web` |
| `noon2-school-web` (facilitator) |
| `noon2-genai-web` |
| `noon2-presenter-web` / `noon2-presenter-native` |

Query pattern:

```
service:noon2-core-http env:prod <profileId|roomId|path|status>
service:noon2-core-ws env:prod <roomId|profileId>
service:noon2-teacher-web env:staging <user|session>
```

Prefer MCP tools from `plugin-datadog-datadog` (setup via `ddsetup` if missing). Summarize + link; do not dump raw payloads.

FE logging conventions live under `noon2-frontend/packages/common/src/datadog/` (`logError`, RUM flows). Backend error span tags: `Noon2ExceptionHandler`.

## Env / API hosts

| Env | Typical hosts |
| --- | --- |
| local | `localhost:8082/noon2-core` |
| dev | `*.dev.noonedu.io`, `backend.dev.noonedu.io` |
| staging | `*.staging.noonedu.io`, `backend.staging.noonedu.io` |
| exp | `*.exp.noonedu.io` |
| prod | `*.noonacademy.com`, `*.studyatnoon.com`, `backend.studyatnoon.com` |

## Composed skills

| Need | Skill |
| --- | --- |
| Read-only MySQL | `noon-mysql` (default staging/local; prod only if asked). Remote = VPN/tunnel + native `mysql-client` — do **not** start Docker Desktop/compose for remote reads |
| VPN for remote DB | `pritunl-vpn` |
| Local MySQL/Redis/Mongo/Kafka | `docker-deps` (local `--env local` only) |
| Local core `:8082` | `run-backend` (+ `auth-port-forward`, `local-auth` as needed) |
| API branch repro | `api-test-scripts` / `backend-api-test-scripts` |
| Datadog MCP missing | `ddsetup` then `ddconfig` if broken |
| After user asks to fix | hand off to `task-plan` → `execute-plan` (or implement directly if scope is tiny) |

## Schema / data

- SQL truth: `noon2_core/ops/db-migrations/schema.sql`
- Runner: `playground/bin/noon_mysql.sh` — SELECT/WITH/SHOW/DESCRIBE/EXPLAIN only
- Remote client: Homebrew `mysql-client` first; Docker `mysql:8.0` only as fallback (not compose)
- Never print `playground/.env` secrets

## First-hop symptom → code

| Symptom | Frontend | Core |
| --- | --- | --- |
| Classroom / live | `packages/common/src/classroom/…`, app `containers/classroom/` | `controller/classroom\|session\|connected_classroom`, `orchestrator/`, `websocket/` |
| API / data | `requests/<domain>/`, interceptors | `controller/<domain>` → service → repository |
| Auth / profile | `requests/login\|profile` | `controller/auth\|user`, `auth/` |
| Jobs | — | `service/scheduler/jobs/`, `QueuedJobConfiguration` |
| School / attendance | facilitator + school requests | `controller/school/` |

Full maps: Bug Agent `service-map.md` files above.

## Ownership rules (short)

- `frontend` — FE code/observability explains it without a required core change
- `core` — core code/data/backend observability explains it without a required FE change
- `cross-repo` — cause or fix spans both
- `infrastructure` — deploy/runtime/network/shared service
- `unknown` — evidence does not support the others
