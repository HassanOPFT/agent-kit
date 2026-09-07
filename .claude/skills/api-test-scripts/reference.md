# API test scripts — reference

## TEST_PLAN.md template

```markdown
# <Feature> API test plan

**Controller:** `com.noon.noon2.controller...`
**Base path:** `/noon2-core/...`
**Script:** `test_<feature>.sh`
**Auth:** default (single role from `auth/.env`)

## Prerequisites

- [ ] `noon2-core` running at `BASE_URL`
- [ ] `api-test-scripts/auth/.env` (or scenario `.env`) with credentials
- [ ] Feature flags / seeds (list here)

## Branch matrix

| branch_id | method | path | role | setup | request summary | expected_http | body_oracle (jq) | false_pass guard |
|-----------|--------|------|------|-------|-----------------|---------------|------------------|------------------|
| FOO-CREATE-OK | POST | /foo | admin | live DB id | valid body | 200 | `.id != null` | FOO-CREATE-400 |
| FOO-CREATE-400 | POST | /foo | admin | — | missing required field | 400 | — | paired with OK |

## Alignment (mutating DB)

> Required before any seed/insert. Agent must get user OK.

| action | sql / file | purpose |
|--------|------------|---------|
| seed | `seed/foo.sql` | ... |

## post_run verification

- [ ] `noon_mysql_query "SELECT ..."` — expect ...
- [ ] Mongo / Redis check (document command)

## non_api_branches

- (websocket, cron, external API — manual only)

## Changelog

| date | change |
|------|--------|
| YYYY-MM-DD | initial plan |
```

## branch_id naming

`<AREA>-<VERB>-<BRANCH>`

- `AREA`: short feature code (`GENRPT`, `AIB`, `KBANK`)
- `VERB`: `CREATE`, `GET`, `PUT`, `LIST`, `ADMIN`
- `BRANCH`: `OK`, `400`, `403`, `404`, `DENY`, `VALIDATE`, descriptive suffix

## lib/runner.sh API

Source from scenario script:

```bash
RUNNER_SH="$(cd "${SCRIPT_DIR}/../lib" && pwd)/runner.sh"
source "$RUNNER_SH"
```

| Function | Purpose |
|----------|---------|
| `noon_runner_load_env` | Load `auth/.env` then scenario `.env` |
| `noon_runner_ensure_auth` | Default: `auth.sh` → `ACCESS_TOKEN`. `NOON_AUTH_MODE=multi_role` for teacher/admin refresh |
| `noon_runner_init_suite <slug> <title>` | Start logs under `logs/` |
| `noon_run_case <branch_id> <name> <role> <method> <path> <json\|''> <http> [jq] [skip_env_var]` | JSON request + assertions |
| `noon_run_get_case <branch_id> <name> <role> <path> <http> [jq] [skip_env_var]` | GET helper |
| `noon_mysql_query "<sql>"` | Read-only docker mysql |
| `noon_mysql_apply_seed <path>` | Requires `NOON_MYSQL_APPLY_OK=1` |
| `noon_runner_finalize_suite` | Write JSON report; exit 1 if `FAILED>0` |

**Roles:** `admin`, `teacher`, `default` (ACCESS_TOKEN), `none` (no auth header).

**Env overrides:**

| Variable | Effect |
|----------|--------|
| `NOON_ALLOW_MULTI_HTTP=1` | Allow comma-separated expected HTTP (discouraged) |
| `NOON_MYSQL_APPLY_OK=1` | Permit `noon_mysql_apply_seed` |
| `MYSQL_CONTAINER` | Default `mysql` |
| `MYSQL_USER` / `MYSQL_PASSWORD` / `MYSQL_DB` | Docker mysql credentials |

## Auth modes

**Default (preferred):**

```bash
# auth/.env: AUTH_USERNAME, AUTH_PASSWORD
noon_runner_ensure_auth
noon_run_case "..." "..." "admin" ...
```

**Multi-role (rare):** only when the plan needs two JWTs. Skip unauth 401/403 cases unless the user asks.

## JSON log shape (per test event)

```json
{
  "event": "test",
  "branch_id": "GENRPT-CREATE-OK",
  "method": "POST",
  "endpoint": "/genai-reports",
  "role": "admin",
  "expected_http": "200",
  "actual_code": "200",
  "body_oracle": ".id != null",
  "request_body": { "query": "...", "variables": { } },
  "response_body": { "data": { } }
}
```

`request_body` and `response_body` in `*_full.json` are **parsed JSON objects** (pretty-printed with `indent=2`), not escaped strings. Non-JSON bodies (plain text/HTML) stay as strings.

## jq body oracles (examples)

| Intent | jq filter |
|--------|-------------|
| Has id | `.id != null` |
| Paginated | `.data != null and (.data \| length) >= 0` |
| Error body | `.message != null` or `.error != null` |
| Enum field | `.status == "OPEN"'` |

Pass the filter as the 8th argument to `noon_run_case` (no `jq` prefix).
