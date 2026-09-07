---
name: resequence-migration
description: >-
  Renumbers one or more Flyway versioned migration files under noon2_core
  (V{number}__*.sql) to the next free version slots, preserving __description
  suffixes. Filesystem-only; no DB or Flyway commands. Use when the user asks
  to resequence, renumber, bump version, or fix migration file numbering for a
  given migration file after merge/rebase conflicts, or to avoid version
  collisions without running local Flyway repair/migrate.
disable-model-invocation: true
---

# Resequence migration (filesystem only)

Use this skill when the user wants **only** to renumber Flyway **versioned** migration **files** in `noon2_core`. It does **not** connect to MySQL, edit `flyway_schema_history`, run `repair`/`migrate`, or generate rollback SQL. For that, use `flyway-local-resequence`.

## Scope

- **Module:** `noon2_core` only.
- **Directory:** `noon2_core/src/main/resources/db/migration`.
- **Files:** `V{integer}__*.sql` only. Ignore repeatable migrations (`R__*.sql`).

## Hard non-goals

- No Docker, JDBC, or SQL execution against any database.
- No Flyway CLI (`repair`, `migrate`, `info`).
- If the old version was **already applied** locally or remotely, renaming the file is **not** enough — stop and point the user to `flyway-local-resequence` (history + schema alignment).

## Algorithm

1. **List** all versioned migrations: match `V([0-9]+)__.*\.sql` (case-sensitive `V`).
2. **Parse** version integer from each filename.
3. **Input set:** migration file path(s) the user gave (must live under the migration directory). If unclear, ask which files to move.
4. **Baseline max:** among files **not** in the input set, compute `max_version = max(parsed versions)`; if none, `max_version = 0`.
5. **Ordering:** sort input files by **current** version ascending (stable tie-break by filename).
6. **Assign** new versions: first file gets `max_version + 1`, next gets `max_version + 2`, etc.
7. **Rename** each file so only the `V<number>` prefix changes; keep the `__...sql` suffix **byte-for-byte identical**.
8. **Verify** after renames: no duplicate `V<number>__` prefixes; sorted list has strictly increasing versions.

## Rename rules

- Preserve everything after the first `__` in the basename (per Flyway convention in this repo).
- Example: `V579__create_genai_report_table.sql` → `V596__create_genai_report_table.sql` if `596` is the next free slot.
- Prefer `git mv` when in a git worktree so renames are tracked cleanly.

## Collision / sanity checks before renaming

- If any **new** version number already exists on a file **outside** the input set, stop and report the conflict; do not partially rename.
- If two input files would map to the same new number (should not happen if ordering is correct), stop.

## Output

Return a short summary:

- Table `old_filename -> new_filename` (or `old_version -> new_version`).
- Note explicitly: **filesystem only** — if Flyway already recorded the old version, use `flyway-local-resequence`.

### Required closing line (print to user)

Always end with **one final line** the user can scan or grep, after any table or bullets. Use this exact prefix (case-sensitive):

`Resequence migration:`

Then the mapping(s), basename only, comma-separated if multiple. Use ASCII `->` between old and new.

Examples:

- `Resequence migration: V579__create_genai_report_table.sql -> V596__create_genai_report_table.sql`
- `Resequence migration: V580__a.sql -> V597__a.sql, V581__b.sql -> V598__b.sql`

If the run stopped without renaming (conflict, wrong path, DB already applied old version), still print the line with a short reason after the colon, e.g. `Resequence migration: skipped — <reason>`.

## Relation to `flyway-local-resequence`

| Concern | This skill | `flyway-local-resequence` |
| --- | --- | --- |
| Rename `V*.sql` files | Yes | Yes (as one step) |
| DB / history / repair / migrate | No | Yes |
