---
name: flyway-local-resequence
description: Resolve Flyway migration version conflicts in noon2-core after merging main by renumbering branch migrations, generating/executing local rollback SQL, repairing Flyway history, and reapplying migrations via Docker. Use when migration numbers are outdated, duplicated, or need resequencing.
disable-model-invocation: true
---

# Flyway Local Resequence (noon2-core)

Use this skill when `noon2-core` migration versions conflict after merging/rebasing main.

## Scope and Safety

- Target module: `noon2_core` only.
- Target DB: local Docker MySQL only (`mysql:3306/noon2_core`, `host.docker.internal:3306/noon2_core`, or host `localhost:3306/noon2_core` mapped to that container).
- Hard block if DB target is not local.
- Default recovery path includes Flyway `repair`.

## Required Behavior

1. Detect duplicate/outdated Flyway version numbers in `noon2_core/src/main/resources/db/migration`.
2. Inspect `flyway_schema_history` for failed rows (`success = 0`) and duplicate versions.
3. Renumber only branch-added migration files to next available versions.
4. Choose recovery strategy: **per-migration rollback** (default) or **rewind to last-good version** (when history/schema drift is detected).
5. Generate cleanup SQL for partial schema objects from failed applies.
6. Generate rollback or rewind SQL based on strategy.
7. Generate `flyway_schema_history` cleanup SQL for failed + renumbered + rewound rows.
8. Execute cleanup + rollback/rewind SQL automatically after explicit local-safety confirmation.
9. Run Flyway `repair` after cleanup to fix history + checksums.
10. Reapply migrations, then run `repair` again to normalize any drift, then verify with `info`.
11. Detect/report upstream migration blockers distinctly from resequenced migrations.
12. Use an interactive checklist and keep the user informed briefly.

## Interactive Checklist (copy and update while working)

```md
Migration conflict fix progress:
- [ ] 1) Verify local-only target (hard safety gate)
- [ ] 2) Resolve compose/script paths and choose Flyway command strategy
- [ ] 3) Inspect flyway_schema_history (failed rows, duplicate versions)
- [ ] 4) Detect version collisions and branch-owned migration files
- [ ] 5) Plan renumber mapping (old -> new)
- [ ] 6) Rename migration files
- [ ] 7) Choose recovery strategy: per-migration rollback OR rewind-to-last-good
- [ ] 8a) Generate failed-apply cleanup SQL (DROP partial objects)
- [ ] 8b) Generate rollback OR rewind SQL (reverse effects of affected versions)
- [ ] 8c) Generate flyway_schema_history cleanup SQL
- [ ] 9) Execute cleanup + rollback/rewind SQL locally (after explicit confirm)
- [ ] 10) Run Flyway repair (fix history + checksums)
- [ ] 11) Run Flyway migrate
- [ ] 12) Run Flyway repair again (normalize drift) + info verify
- [ ] 13) Report concise summary + changed files + commands run
```

## Local-Only Safety Gate (must pass before any DB mutation)

Run these checks first:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker inspect mysql --format '{{json .NetworkSettings.Ports}}'
```

Allow mutation only if all are true:

- `mysql` container exists and is running.
- MySQL port exposure is local (`0.0.0.0:3306` or loopback mapping on dev machine).
- DB name is `noon2_core`.
- Compose file is a local dev compose file. Prefer this order:
  - `local-custom/docker-compose.deps.yaml`
  - fallback: `docker/deps-docker-compose.yaml`

If any check fails, stop and ask user to fix local env first.

## Preflight Path + Connectivity Resolution

Run before any `repair/migrate` command:

```bash
ls local-custom/docker-compose.deps.yaml docker/deps-docker-compose.yaml
ls scripts/flyway-repair.sh
```

Rules:

1. Pick compose path:
   - Use `local-custom/docker-compose.deps.yaml` if present.
   - Else use `docker/deps-docker-compose.yaml`.
   - If neither exists, stop and ask user.
2. Repair command:
   - If `scripts/flyway-repair.sh` exists, use it.
   - Else run `docker compose ... --entrypoint flyway ... repair` directly.
3. DB host resolution for Flyway container:
   - Try `mysql` first (`jdbc:mysql://mysql:3306/noon2_core`).
   - If unresolved/unreachable, fallback to `host.docker.internal`.
   - If both fail, stop and ask user.

## Detection and Renumber Rules

- Parse versioned files matching `V{number}__*.sql`.
- Ignore repeatable migrations (`R__*.sql`).
- Compute:
  - `max_main_version`: highest version from main branch files.
  - branch-added migrations that conflict or are <= `max_main_version`.
- Renumber only branch-added files in ascending old version order.
- New numbers must be strictly increasing from `max_main_version + 1`.
- Preserve migration description suffix (`__...sql`) exactly.

## History Inspection (run before generating SQL)

```sql
-- Failed rows (must be cleaned for Flyway to validate)
SELECT installed_rank, version, description, success
FROM flyway_schema_history
WHERE success = 0
ORDER BY installed_rank DESC;

-- Duplicate / overlapping versions vs branch files
SELECT version, description, success, installed_on
FROM flyway_schema_history
WHERE version IN (...suspect_versions...)
ORDER BY installed_rank;
```

Use the result to classify each suspect version into one of:

- **A. Failed apply** (`success = 0`) → needs failed-apply cleanup SQL.
- **B. Successfully applied old version that will be renumbered** → needs rollback SQL.
- **C. Already correct / no action** → leave alone.

Then **also** spot-check schema vs history for "drift": for each migration that history reports as `Success`, confirm the migration's primary objects (CREATE TABLE / ADD COLUMN) actually exist in the schema. If any reported-success migration's objects are missing, you have **history/schema drift** — switch to the Rewind strategy below.

## Recovery Strategy Decision

Pick one strategy. Default is **per-migration rollback** unless drift is detected.

| Strategy | Use when | Trade-off |
| --- | --- | --- |
| **Per-migration rollback** (default) | Only branch-owned versions are affected; history matches schema. | Surgical, preserves all other applied state. |
| **Rewind to last-good version** | History/schema drift detected (e.g. `Success` rows for objects that no longer exist), or multiple consecutive upstream migrations are blocked because of the drift. | Touches more rows, but restores a known-good baseline before reapplying. Avoids whack-a-mole on cascading failures. |

### When rewind is the right call (signals)

- A migration fails with `Table 'X' doesn't exist` even though history says its CREATE migration succeeded.
- Multiple consecutive migrations downstream of the same domain (e.g., `lesson*`) are blocked.
- User has manually dropped objects locally and you can't trust history past version `N`.

### Rewind algorithm

1. Identify `last_good_version`: the highest version where (a) history says `Success` AND (b) all of that migration's primary objects still exist in schema.
2. Build the **reverse list**: every version `V` where `last_good_version < V <= current_head`. Reverse in **descending version order** so dependents are reversed before parents (FKs, child tables).
3. For each `V` in the reverse list:
   - If `V`'s primary objects already absent → no schema reversal needed (skip schema reverse, still delete history row).
   - Else generate the reverse SQL (DROP/MODIFY back/RE-ADD column with original type).
   - For RE-ADD reversals, look up the original column type from the migration that introduced it (search prior `V*__*.sql` files for the column name).
4. Verify reversibility risk **before executing**:
   - Enum narrowing: `SELECT COUNT(*) FROM <table> WHERE <col> IN (<values_being_removed>)` must be `0`.
   - Column re-add: only safe if dropping it caused no data loss you care about; for local dev this is usually fine.
   - If risk check fails, stop and ask user.
5. Execute reverse SQL in descending order, then `DELETE FROM flyway_schema_history WHERE version IN (<reverse_list>)`.
6. Run `flyway repair` → `migrate` → `repair` → `info`.

### Worked example (real run on this repo)

- Detected drift: history showed `V577 create lesson tables = Success`, but `lesson`, `lesson_curriculum`, `lesson_version` were absent.
- Picked rewind to `V576`.
- Reverse list: `V577..V582`.
- Reversal SQL generated:
  ```sql
  -- V577/V578: schema already absent → no schema reverse, delete history only
  -- V579: ADD COLUMN content_report.image_library_id  → reverse with DROP
  ALTER TABLE content_report DROP COLUMN image_library_id;
  -- V580: cohort_v2.type ENUM widened to add 'ONLINE' → reverse to narrower enum
  --       (verified: SELECT COUNT(*) FROM cohort_v2 WHERE type='ONLINE' = 0)
  ALTER TABLE cohort_v2 MODIFY COLUMN `type` ENUM('HOMEROOM','GROUP') DEFAULT 'GROUP' NULL;
  -- V581: DROP COLUMN session_task_completed.topic_ids → reverse with ADD
  --       (original type from V553: VARCHAR(512))
  ALTER TABLE session_task_completed ADD COLUMN topic_ids VARCHAR(512) NULL;
  -- V582: schema reverse not needed (DROP COLUMN never applied)
  -- History rewind
  DELETE FROM flyway_schema_history WHERE version IN ('577','578','579','580','581','582');
  ```
- Then `flyway repair → migrate → repair → info` reapplied 19 migrations cleanly to V595.

## Cleanup + Rollback SQL Strategy (local only)

Generate three SQL blocks, in this order:

1. **Failed-apply cleanup** (case A): drop partial schema objects from the failed migration.
   - Use guarded statements: `DROP TABLE IF EXISTS ...`, `DROP INDEX IF EXISTS ...`, `ALTER TABLE ... DROP COLUMN IF EXISTS ...` (MySQL 8 supports `IF EXISTS` on most).
   - If reverse operations are unsafe/unclear, stop and ask user.
2. **Rollback for successfully applied old versions** (case B): reverse the migration's effects.
   - Make idempotent (existence guards on tables/indexes/constraints/columns).
   - If reversal is destructive or ambiguous, stop and ask for approval.
3. **Flyway history cleanup** (always last):

```sql
DELETE FROM flyway_schema_history
WHERE version IN (...failed_versions..., ...renumbered_old_versions...);
```

Execute all three locally only, in order, after explicit user confirm.

## Flyway Repair → Migrate → Repair

Order matters. Run in this exact sequence after cleanup + rollback SQL has executed:

```bash
# 1) First repair: drops failed history rows, fixes checksums
./scripts/flyway-repair.sh

# 2) Verify state before migrate
docker compose -f local-custom/docker-compose.deps.yaml run --rm --no-deps --entrypoint flyway flyway-pre -url=jdbc:mysql://mysql:3306/noon2_core -user=root -password=rootpassword -locations=filesystem:/flyway/sql info

# 3) Apply renumbered migrations
docker compose -f local-custom/docker-compose.deps.yaml run --rm --no-deps --entrypoint flyway flyway-pre -url=jdbc:mysql://mysql:3306/noon2_core -user=root -password=rootpassword -locations=filesystem:/flyway/sql migrate

# 4) Final repair: normalize any drift introduced during migrate (rare, but cheap insurance)
./scripts/flyway-repair.sh

# 5) Final verify
docker compose -f local-custom/docker-compose.deps.yaml run --rm --no-deps --entrypoint flyway flyway-pre -url=jdbc:mysql://mysql:3306/noon2_core -user=root -password=rootpassword -locations=filesystem:/flyway/sql info
```

Why two repairs:

- **Pre-migrate repair** is mandatory when history has failed rows or stale checksums (the actual error in your log: `Detected failed migration to version 581/582`).
- **Post-migrate repair** is defensive: if a renamed migration's checksum drifted vs. history, this normalizes it without re-running migrations.

If `repair` fails, show exact error and stop for user decision.

If `migrate` fails:

1. Run `flyway info` immediately.
2. Classify failure:
   - If failure is in a resequenced target migration, report as resequence failure.
   - If failure is in an upstream/non-target migration (e.g. older/main-chain migration), report as **upstream blocker** and mark run as **partial success** (resequence done, chain blocked).
3. Do not auto-edit unrelated migrations. Ask user whether to proceed with blocker-specific fix.

## User Prompts to Ask (brief)

Ask these before executing SQL:

1. "Confirm local-only DB mutation on Docker mysql (`noon2_core`)?"
2. "Confirm executing generated rollback SQL now?"

If user confirms, proceed without extra delay.

## Output Format

Return concise final output with:

- Collision summary and renumber map (`old -> new`).
- Rollback SQL executed (short form).
- Flyway commands run (including chosen compose path + DB host).
- Final `info` status (success/fail/partial-success-with-upstream-blocker).
- File list changed.

## Non-Goals

- Do not target remote/staging/prod DBs.
- Do not modify `noon2-auth` migrations in this workflow.
- Do not renumber migrations that are not owned by current branch.
