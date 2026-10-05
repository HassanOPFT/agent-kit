---
name: api-test-scripts
description: >-
  Builds branch-level API test plans and bash smoke scripts under api-test-scripts/
  for any running HTTP API (Nest, Express, Spring, etc.). Inventories decision
  branches, writes TEST_PLAN.md, generates test_*.sh using auth/auth.sh and
  lib/runner.sh, and enforces anti-false-pass checks (strict HTTP + jq body
  oracles). Use when changing controllers/routes, REST endpoints, api-test-scripts,
  smoke tests, or live integration tests against local/docker.
---

# API Test Scripts

Shell-first live-stack tests under `api-test-scripts/`. Complements unit/e2e
tests that mock the app — these hit a **running** API.

**Default workflow:** Phase A → Phase B → Phase C in one run. Do **not** stop
after the test plan unless the user explicitly asks for plan-only. Do **not**
apply DB seeds/mutations until the user aligns (see Phase A Alignment).

If the project has no harness yet, copy templates from this skill’s
[`scripts/`](scripts/) into `api-test-scripts/lib/runner.sh` and
`api-test-scripts/auth/auth.sh`, then adapt auth to the target API. Ensure
`api-test-scripts/auth/.env` exists (from `.env.example`) so the user can set
credentials.

## When to use

- New or changed HTTP controllers / routes / handlers
- User asks for API test scripts, branch coverage, or false-pass-safe smoke tests
- Complement (not replace) mocked unit tests — those use mocks; these hit a live app

## Phase A — Branch inventory → `TEST_PLAN.md`

1. Identify scope: controller/route files, services, DTOs/schemas, existing tests,
   existing `api-test-scripts/<feature>/`.
2. For each endpoint, list **decision branches**:

| Source | Branches to capture |
|--------|---------------------|
| Auth guards | skip unauth 401/403 unless user asks; wrong-role 403 only if required |
| Validation (`@Valid`, Zod, class-validator, …) | happy body, missing/invalid field → 400 |
| Path/query params | optional filters, invalid enum, unknown id → 404 |
| Service `if` / flags | empty state, conflict → 4xx |
| Role-scoped paths | prefer **one** JWT that covers all happy paths |

3. Create or update `api-test-scripts/<kebab-feature>/TEST_PLAN.md` using the
   template in [reference.md](reference.md).

**Rules:**

- **One authenticated identity per plan** when one token satisfies all happy paths.
  Do not duplicate the same branch for every role.
- Stable `branch_id`: `<AREA>-<VERB>-<BRANCH>` (e.g. `ITEMS-CREATE-400`).
- One **primary** `expected_http` per row. Multiple codes only with
  `justification` in the plan and `API_ALLOW_MULTI_HTTP=1` in the script.
- Pair every happy path with a **negative control** (400/404/…), not a second role.
  Do **not** add unauthenticated cases unless the user asks.
- **Body oracle required** for every JSON response: jq filter as the 8th arg to
  `api_run_case` (HTTP + shape). Status alone is not enough.
- List **prerequisites**: running server, seeds, feature flags, env vars.
- **DB mutations:** prefer live read queries. For INSERT/UPDATE/DELETE or seed
  files, add an **Alignment** subsection and wait for user OK before applying.
- **Out of scope:** websockets, async jobs, third-party webhooks — list under
  `non_api_branches` (no fake PASS).

4. Continue immediately into Phase B (do not wait for plan approval). Present the
   matrix in the final summary after Phase C.

## Phase B — Scenario folder + script

**Layout:**

```
api-test-scripts/
├── AGENTS.md                 # optional index of feature folders
├── auth/
│   ├── auth.sh               # obtain ACCESS_TOKEN (login or static)
│   ├── .env.example
│   └── .env                  # user credentials (gitignored)
├── lib/
│   └── runner.sh             # shared harness (from skill scripts/)
└── <kebab-feature>/
    ├── TEST_PLAN.md
    ├── .env.example
    ├── .gitignore            # .env, logs/, *.log
    ├── test_<feature>.sh
    ├── seed/                 # optional; apply only after alignment
    └── logs/                 # gitignored
```

**`test_<feature>.sh` skeleton:**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$(cd "${SCRIPT_DIR}/../lib" && pwd)/runner.sh"

api_runner_load_env
api_runner_ensure_auth || exit 1
api_runner_init_suite "<slug>" "<Feature> API branch suite"

api_run_case "AREA-VERB-OK" "description" "default" "POST" "/path" '{"k":"v"}' "200" '.id != null'

api_runner_finalize_suite
```

- Source `../lib/runner.sh` (never copy per feature).
- Default auth: `api_runner_ensure_auth` → `auth/auth.sh` + `auth/.env`.
- Map each `TEST_PLAN.md` row to one `api_run_case` / `api_run_get_case`.
- `role=none` for unauthenticated requests (no `Authorization` header).
- Logs: `logs/<slug>_summary.txt` + `logs/<slug>_full.json` (do not commit).

## Phase C — Anti-false-pass validation

| Check | Action |
|-------|--------|
| Plan ↔ script | Every `branch_id` has a matching `api_run_case` |
| Strict HTTP | No `200,400,500` unless justified + `API_ALLOW_MULTI_HTTP=1` |
| Body oracle | Every JSON response has a jq filter; no always-true `.` |
| Negative control | Each allow path has a paired deny/validate branch |
| SKIP ≠ PASS | Missing env/token → SKIP; suite fails only if `FAILED>0` |
| Run script | `bash api-test-scripts/<feature>/test_<feature>.sh` against live API |
| Review logs | Confirm request/response in `logs/*_full.json` |
| Post-run | Manual DB/cache checks from `TEST_PLAN.md` |

If the API is not running or `auth/.env` credentials are missing, still deliver
plan + script; report run as SKIP/blocked with clear next steps (start API, fill
`.env`). Do not treat a blocked run as a completed green suite.

**False-pass signals:** wrong path still 200; feature off returns 404 but test
expects 200; oracle always true; overly wide HTTP list.

## Reference

- [reference.md](reference.md) — `TEST_PLAN.md` template, runner API, auth
- [examples.md](examples.md) — target shapes
- [scripts/runner.sh](scripts/runner.sh) — portable harness → `api-test-scripts/lib/runner.sh`
- [scripts/auth.sh](scripts/auth.sh) — login helper template → `api-test-scripts/auth/auth.sh`
- [scripts/auth.env.example](scripts/auth.env.example) — → `api-test-scripts/auth/.env.example`
