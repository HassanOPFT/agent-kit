# API test scripts — reference

## TEST_PLAN.md template

```markdown
# <Feature> API test plan

**Entry points:** `path/to/controller-or-router`
**Base URL env:** `BASE_URL` (e.g. `http://localhost:3000`)
**Script:** `test_<feature>.sh`
**Auth:** default (single token from `auth/.env` / login)

## Prerequisites

- [ ] API running at `BASE_URL`
- [ ] `api-test-scripts/auth/.env` (or scenario `.env`) with credentials / token
- [ ] Seeds / flags (list here)

## Branch matrix

| branch_id | method | path | role | setup | request summary | expected_http | body_oracle (jq) | false_pass guard |
|-----------|--------|------|------|-------|-----------------|---------------|------------------|------------------|
| FOO-CREATE-OK | POST | /foo | default | live id | valid body | 200 | `.id != null` | FOO-CREATE-400 |
| FOO-CREATE-400 | POST | /foo | default | - | missing required field | 400 | `.message != null or .error != null or .statusCode == 400` | paired with OK |

## Alignment (mutating DB)

> Required before any seed/insert. Agent must get user OK.

| action | sql / file / command | purpose |
|--------|----------------------|---------|
| seed | `seed/foo.sql` | ... |

## post_run verification

- [ ] DB / cache check (document command)
- [ ] Re-list endpoint confirms side effect

## non_api_branches

- (websocket, cron, external webhook — manual only)

## Changelog

| date | change |
|------|--------|
| YYYY-MM-DD | initial plan |
```

## branch_id naming

`<AREA>-<VERB>-<BRANCH>`

- `AREA`: short feature code (`ITEMS`, `AUTH`, `USERS`, …)
- `VERB`: `CREATE`, `GET`, `PATCH`, `LIST`, `DELETE`, …
- `BRANCH`: `OK`, `400`, `403`, `404`, `DENY`, `VALIDATE`, or a short label

## lib/runner.sh API

Copy [scripts/runner.sh](scripts/runner.sh) to `api-test-scripts/lib/runner.sh`.

```bash
RUNNER_SH="$(cd "${SCRIPT_DIR}/../lib" && pwd)/runner.sh"
# shellcheck source=/dev/null
source "$RUNNER_SH"
```

| Function | Purpose |
|----------|---------|
| `api_runner_load_env` | Load `auth/.env` then scenario `.env` |
| `api_runner_ensure_auth` | Obtain `ACCESS_TOKEN` via `auth/auth.sh` |
| `api_runner_init_suite <slug> <title>` | Start logs under `logs/` |
| `api_run_case <branch_id> <name> <role> <method> <path> <json\|''> <http> [jq] [skip_env_var]` | Request + assertions |
| `api_run_get_case <branch_id> <name> <role> <path> <http> [jq] [skip_env_var]` | GET helper |
| `api_runner_finalize_suite` | Write JSON report; exit 1 if `FAILED>0` |

**Roles:** `default` (use `ACCESS_TOKEN`), `none` (no auth header). Extra named roles
only if `auth/auth.sh` populates `ACCESS_TOKEN_<ROLE>` and the plan requires them.

**Env overrides:**

| Variable | Effect |
|----------|--------|
| `BASE_URL` | API origin (required) |
| `API_ALLOW_MULTI_HTTP=1` | Allow comma-separated expected HTTP (discouraged) |
| `API_AUTH_HEADER` | Default `Authorization` |
| `API_AUTH_SCHEME` | Default `Bearer` |

## Auth

**Default (preferred):**

```bash
# auth/.env: AUTH_EMAIL / AUTH_PASSWORD or ACCESS_TOKEN=
api_runner_ensure_auth
api_run_case "..." "..." "default" ...
```

Copy `auth/.env.example` → `auth/.env` and fill credentials (gitignored).
Adapt [scripts/auth.sh](scripts/auth.sh) to the API’s login contract
(e.g. `POST /auth/login` → `.accessToken`).

## Workflow

Default: Phase A (plan) → Phase B (script) → Phase C (validate + run) in one
invocation. Stop after the plan only when the user asks for plan-only.
DB seed/mutation still requires Alignment OK before applying.

## JSON log shape (per test event)

```json
{
  "event": "test",
  "branch_id": "ITEMS-CREATE-OK",
  "method": "POST",
  "endpoint": "/items",
  "role": "default",
  "expected_http": "201",
  "actual_code": "201",
  "body_oracle": ".id != null",
  "request_body": { "name": "…" },
  "response_body": { "id": "…" }
}
```

Parsed JSON bodies are objects in `*_full.json`; non-JSON stays a string.

## jq body oracles (examples)

| Intent | jq filter |
|--------|-----------|
| Has id | `.id != null` |
| List / page | `.items != null or .data != null or (type == "array")` |
| Error body | `.message != null or .error != null or .statusCode != null` |
| Field value | `.status == "ACTIVE"` |
