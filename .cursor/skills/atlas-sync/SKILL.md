---
name: atlas-sync
description: >-
  Syncs the local noon2_core MySQL schema to ops/db-migrations/schema.sql with
  Atlas. Dry-runs first, skips when already in sync, and applies only pending
  changes. Use after editing schema.sql, before bootRun when the local schema
  may have drifted, after a fresh mysql volume, or when the user says
  "atlas sync", "apply schema", "sync db schema", or hits Hibernate
  "table/column not found" errors locally.
disable-model-invocation: true
---

# Atlas sync (check-then-run)

Bring the **local** Docker MySQL in line with noon2_core
`ops/db-migrations/schema.sql`. Prefer the `local-custom` wrapper — it re-applies
the schema to a long-lived `mysql_data` volume, which the one-shot compose
`atlas-migrate` step does not.

**Scope:** local-dev skill. Do **not** document it in shared `AGENTS.md` unless it
is already there. It only touches the local Docker database, never dev / staging /
prod.

**Never print** DB passwords, `.env` contents, `MYSQL_ROOT_PASSWORD`, or any
connection URL that embeds a secret. The scripts read credentials internally.

## When to use

- After you edit `schema.sql` (add/change a column, index, or table).
- Before **run-backend** / `bootRun` when the local schema may be stale.
- After a fresh `mysql_data` volume (e.g. `docker volume rm`, reset scripts) —
  the compose one-shot only seeds the schema on first `up`.
- When local queries fail with missing table/column errors.

## Atlas philosophy (read the README)

`schema.sql` is the **single source of truth**. Atlas inspects the live DB, diffs
it against `schema.sql`, and converges it. There are **no migration files and no
hand-written `ALTER TABLE`** — edit `schema.sql` to describe the end state. Full
model, buckets, and pt-osc details: `ops/db-migrations/README.md`.

## Paths

From the **noon2_core** repo root:

| Item | Path |
| --- | --- |
| Preferred wrapper | `../local-custom/apply-atlas-schema.sh` |
| Host Atlas fallback | `ops/db-migrations/apply-schema.sh` |
| Schema source | `ops/db-migrations/schema.sql` |
| Atlas config | `ops/db-migrations/atlas.hcl` |

## Prerequisites

1. Run **docker-deps** first so the `mysql` container is up and healthy. If it is
   not running, the wrapper exits with an error — run **docker-deps**, then retry.
2. Do not source-and-echo `.env`. The wrapper supplies local compose/env defaults
   internally.

## 1. Check (dry-run first — always)

```bash
cd "$(git rev-parse --show-toplevel)"   # noon2_core root
DRY_RUN=true ../local-custom/apply-atlas-schema.sh
```

Interpret the plan:

- **No pending changes** ("already matches" / empty plan / no `;` statements) →
  **skip apply**. Report `atlas-sync: in sync`. Stop here.
- **Pending, non-destructive** (only `CREATE TABLE`, `ADD COLUMN`, `ADD INDEX`,
  nullable/defaulted columns, FK adds) → proceed to apply.
- **Destructive** (`DROP TABLE`, `DROP COLUMN`, or a data-loss change) → **stop**.
  Show the dry-run summary and ask the user before applying. Apply only after the
  user confirms.

If the wrapper is missing, fall back only after user confirmation (needs the
`atlas` CLI on `PATH`; never paste secrets into chat):

```bash
./ops/db-migrations/apply-schema.sh   # honours DRY_RUN=true the same way
```

## 2. Apply (only when the dry-run shows pending, approved changes)

```bash
../local-custom/apply-atlas-schema.sh
```

Do **not** set `DRY_RUN` for the real apply. The wrapper tries the compose
`atlas-migrate` service, then falls back to `docker run` on the MySQL container
network if compose cannot resolve the `mysql` hostname.

Optional local seeds after apply (only if the user asks):

```bash
cd ../local-custom
docker compose -f docker-compose.deps.yaml run --rm local-seed-required
docker compose -f docker-compose.deps.yaml run --rm local-seed-post
```

## 3. Verify

Re-run the dry-run; a clean plan confirms the DB now matches `schema.sql`:

```bash
DRY_RUN=true ../local-custom/apply-atlas-schema.sh
```

## Failures → next action

| Failure | Next action |
| --- | --- |
| MySQL container not running | Run **docker-deps**, then re-run this skill |
| `schema.sql` / `atlas.hcl` missing | Confirm you are in noon2_core and set `NOON2_CORE_ROOT` if the checkout is not the sibling of `local-custom` |
| Compose path fails | Wrapper auto-falls back to `docker run` on the MySQL network; read its error if that also fails |
| Destructive plan in dry-run | Stop; show the summary; get explicit user OK before apply |
| Docker not installed / daemon down | Start Docker Desktop; re-run **docker-deps** |

## Closing line

Report exactly one:

- `atlas-sync: in sync` — dry-run clean, nothing applied
- `atlas-sync: applied — <what changed, high level>`
- `atlas-sync: failed — <reason + next action>`
