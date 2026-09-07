---
name: api-test-scripts
description: Builds branch-level API test plans and shell scripts under api-test-scripts/ for noon2-core controller changes. Inventories decision branches, writes TEST_PLAN.md, generates test_*.sh using auth/auth.sh and lib/runner.sh, and enforces anti-false-pass checks. Use when changing controllers, REST endpoints, api-test-scripts, smoke tests, or integration tests against local/docker.
---

# Backend API Test Scripts

Shell-first live-stack tests under `api-test-scripts/`. Read [api-test-scripts/AGENTS.md](../../../api-test-scripts/AGENTS.md) first.

**Default workflow:** Phase A → user review → Phase B → Phase C validation. Do **not** apply MySQL seeds/inserts until the user aligns (see Phase A).

## When to use

- New or changed `@RestController` / endpoints in `noon2-core`
- User asks for api test scripts, branch coverage, or false-pass-safe smoke tests
- Complement (not replace) Java `@WebMvcTest` — those use mocks; these hit a running app

## Phase A — Branch inventory → `TEST_PLAN.md`

1. Identify scope: controller path(s), service impl, DTOs, existing Java tests, existing `api-test-scripts/<feature>/`.
2. For each endpoint, list **decision branches**:

| Source | Branches to capture |
|--------|---------------------|
| `@PreAuthorize` | skip unauth 401/403 in shell suites (env-specific); wrong-role 403 only if explicitly required |
| `@Valid` / Bean Validation | happy body, missing/invalid field → 400 |
| Path/query params | optional filters, invalid enum, unknown id → 404 |
| Service `if` / flags | feature flags, empty state, conflict → 4xx |
| Admin vs public paths | same **single** authenticated role when one JWT satisfies all happy paths |

3. Create or update `api-test-scripts/<kebab-feature>/TEST_PLAN.md` using the template in [reference.md](reference.md).

**Rules:**

- **One authenticated role per plan** — pick a single role (usually `admin` or `default` from `auth/.env`) that satisfies `@PreAuthorize` for every happy-path endpoint. Do **not** duplicate the same branch for teacher vs admin (5 cases ≠ 10 rows).
- Every branch gets a stable `branch_id`: `<AREA>-<VERB>-<BRANCH>` (e.g. `GENRPT-CREATE-400`).
- One **primary** `expected_http` per row (single code). Multiple codes only with `justification` in the plan and `NOON_ALLOW_MULTI_HTTP=1` in the script.
- Pair every happy path with a **negative control** on behaviour (400, 404), not on a second role. **Do not** add unauthenticated cases unless the user asks.
- **Body oracle required** for every branch that returns JSON: pass a jq filter as the 8th arg to `noon_run_case` (HTTP + shape). Status code alone is not sufficient.
- Add `body_oracle` (jq filter) whenever the status alone is ambiguous.
- List **prerequisites**: seeds, feature flags, env vars, Mongo/Redis checks.
- **MySQL (docker):** prefer **live** rows over scenario seeds when possible (`ORDER BY RAND() LIMIT 1` with filters that exclude known seed files / `source` markers). Document read checks in `post_run`; for **INSERT/UPDATE/DELETE** or seed files, add an **Alignment** subsection (SQL summary + ask user). Do not run `noon_mysql_apply_seed` until user confirms and sets `NOON_MYSQL_APPLY_OK=1`.
- **Out of scope:** websocket, async jobs, external providers — list under `non_api_branches` (no fake PASS).

4. **Stop after Phase A** unless the user says to implement. Present the matrix for review.

## Phase B — Scenario folder + script

**Layout:**

```
api-test-scripts/<kebab-feature>/
├── TEST_PLAN.md          # committed contract
├── .env.example
├── .gitignore            # .env, logs/, *.log
├── test_<feature>.sh     # executable
├── seed/                 # optional *.sql (apply only after alignment)
└── logs/                 # gitignored artifacts
```

**`.env.example`:** `BASE_URL`, scenario ids. Default auth via `auth/.env` only; `NOON_AUTH_MODE=multi_role` only when the plan documents a rare deny-role case.

**`test_<feature>.sh` skeleton:**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER_SH="$(cd "${SCRIPT_DIR}/../lib" && pwd)/runner.sh"
# shellcheck source=/dev/null
source "$RUNNER_SH"

noon_runner_load_env
noon_runner_ensure_auth || exit 1
noon_runner_init_suite "<slug>" "<Feature> API branch suite"

# Cases mirror TEST_PLAN.md branch_id rows:
noon_run_case "AREA-VERB-OK" "description" "admin" "POST" "/path" '{"k":"v"}' "200" '.id != null'

noon_runner_finalize_suite
```

- Source `../lib/runner.sh` (not per-feature copies).
- **Auth:** default `noon_runner_ensure_auth` → `auth/auth.sh` + optional `auth/.env` (one token for all authenticated cases). Use `role=none` for 401. Avoid `multi_role` unless the plan explicitly requires a second JWT.
- Map each `TEST_PLAN.md` row to one `noon_run_case` / `noon_run_get_case` with matching `branch_id`.
- Pass `body_oracle` as the 8th argument when the plan specifies jq (e.g. `'.id != null'`).
- Optional 9th arg: env var name to **SKIP** if unset (never PASS without data).
- `role=none` for unauthenticated requests (no Authorization header).

**Logging:** `logs/<slug>_summary.txt` (human) + `logs/<slug>_full.json` (full request/response per case; bodies are nested JSON objects when parseable). Do not commit logs.

Update `api-test-scripts/AGENTS.md` subfolder table when adding a new feature folder.

## Phase C — Anti–false-pass validation

Before marking work done:

| Check | Action |
|-------|--------|
| Plan ↔ script | Every `branch_id` in `TEST_PLAN.md` has a matching `noon_run_case` |
| Strict HTTP | No `200,400,500` unless justified in plan + `NOON_ALLOW_MULTI_HTTP=1` |
| Body oracle | Every JSON response has a jq filter; no empty oracle on 200/400/404 |
| Negative control | Each allow path has a paired deny/validate branch |
| SKIPPED ≠ PASS | Missing env/token → SKIP in summary, suite may still exit 0 only if `FAILED=0` |
| Run script | `bash api-test-scripts/<feature>/test_<feature>.sh` against local stack |
| Review logs | Open `logs/*_full.json`; confirm request/response match intent |
| Post-run | Execute manual steps from `TEST_PLAN.md` post_run (DB/Mongo) |

**False pass signals to fix:** wrong path still 200; feature flag off returns 404 but test expects 200; oracle always true (`.'`); overly wide HTTP list.

## MySQL (docker)

- Read-only: `noon_mysql_query "SELECT ..."` (container `MYSQL_CONTAINER`, default `mysql`).
- Seeds: `noon_mysql_apply_seed seed/foo.sql` only after user alignment and `NOON_MYSQL_APPLY_OK=1`.
- Show the user the SQL (or file path) before any mutating apply.

## Reference

- [reference.md](reference.md) — `TEST_PLAN.md` template, runner API, auth modes
- [examples.md](examples.md) — gold references in-repo
- `api-test-scripts/lib/runner.sh` — shared harness
