---
name: quality-checks
description: Run noon2-frontend PR CI checks locally (Prettier, ESLint, TypeScript, translations, fallow, unit coverage, contract) before commit, push, or opening a PR. Use when commit-workflow, pr-workflow, or execute-plan runs in noon2-frontend.
---

# Quality checks (noon2-frontend)

Run from the **noon2-frontend** repo root. Do **not** add or change `package.json` or
`scripts/*` — use existing yarn scripts only.

Source of truth: `.github/workflows/pr-wf.yaml`, `.github/workflows/contract-openapi.yml`,
and `.github/actions/check-changes`.

## Hard gate (callers must obey)

`commit-workflow`, `pr-workflow`, and `execute-plan` **must** run this skill and treat
any FAIL as a stop:

- **Do not** `git commit`, `git push`, or `gh pr create` while a required step is FAIL.
- Fix failures (or report and stop) before continuing.
- **Do not** push and wait for GitHub Actions — run these checks locally first.

## Scope

| Mode       | When to use                           | Changed files                                 |
| ---------- | ------------------------------------- | --------------------------------------------- |
| **commit** | Before `commit-workflow` / committing | Staged + unstaged only                        |
| **pr**     | Before push / `gh pr create`          | `git diff` vs base + staged + unstaged        |

Default base branch for **pr** mode: `master`.

## CI job → local command map

| CI job (pr-wf.yaml)   | Local command (pr scope)                                              | commit scope                          |
| --------------------- | ----------------------------------------------------------------------- | ------------------------------------- |
| Check Prettier        | `yarn format:check`                                                     | `yarn prettier --check` on changed fmt files |
| Lint                  | `yarn lint`                                                             | `yarn lint <changed ts/tsx/js…>`      |
| Check TypeScript (*)  | `yarn workspace <ws> check-types` per changed workspace                 | Same, changed workspaces only         |
| Check Translations    | `yarn workspace <ws> run check-translations`                            | If `src/translations/*` touched       |
| Check Arabic Trans.   | `yarn workspace <ws> run check-arabic-translations`                     | If `src/translations/*` touched       |
| Check Code Quality    | `yarn fallow dead-code --circular-deps` + `--unlisted-deps`             | Skip on commit                        |
| Unit Tests (*)        | `yarn workspace <ws> run coverage:summary` per changed workspace       | `yarn workspace <ws> test` if tests touched |
| FE schema vs BE spec  | `yarn workspace common jest -c jest.contract.config.js --ci`            | If `packages/common/src/contract/**` changed |

Title / label gates (no local yarn): `pr-wf-title-check.yaml`, `pr-wf-bug-critical-label-check.yaml`.

Build Web / Android / iOS jobs are **not** required before push — too slow; CI runs them.

## 1. Collect changed paths

**PR mode** (`BASE=master`):

```bash
BASE=master
CHANGED=$({
  git diff --diff-filter=ACMR --name-only "${BASE}"...HEAD 2>/dev/null
  git diff --diff-filter=ACMR --name-only --cached HEAD
  git diff --diff-filter=ACMR --name-only HEAD
} | sort -u)
```

**Commit mode:**

```bash
CHANGED=$({
  git diff --diff-filter=ACMR --name-only HEAD
  git diff --diff-filter=ACMR --name-only --cached HEAD
} | sort -u)
```

If `CHANGED` is empty, report "no changed files" and stop.

## 2. Detect changed workspaces (matches CI)

All workspaces: `common`, `admin`, `facilitator`, `genai`, `presenter`, `student`, `teacher`.

Logic (same as `.github/actions/check-changes`):

- A workspace is **changed** if any file under `packages/<workspace>/` differs from base
  (PR mode: `git diff $BASE...HEAD`; commit mode: staged/unstaged paths).
- If **`common`** changed, treat **every** workspace as changed (CI reruns all).

```bash
# Example for PR mode — set CHANGED_WS array in shell after inspecting CHANGED / git diff
COMMON_CHANGED=false
# if packages/common in diff → COMMON_CHANGED=true and CHANGED_WS=(common admin facilitator genai presenter student teacher)
# else CHANGED_WS = only workspaces with paths under packages/<ws>/
```

## 3. Commit scope (fast)

Run on every real commit, in order:

1. **Prettier** — changed formattable files only (`.ts`, `.tsx`, `.js`, `.jsx`, `.json`, `.md`):
   ```bash
   yarn prettier --check <file1> <file2> ...
   ```
   Skip if none.

2. **ESLint** — changed `.ts`, `.tsx`, `.js`, `.jsx` only:
   ```bash
   yarn lint <file1> <file2> ...
   ```

3. **TypeScript** — once per workspace in `CHANGED_WS`:
   ```bash
   bash scripts/version_vars packages/<workspace>   # pr scope only; optional on commit
   yarn workspace <workspace> check-types
   ```

4. **Translations** — for each workspace in `CHANGED_WS` with translation file changes:
   ```bash
   yarn workspace <workspace> run check-translations
   yarn workspace <workspace> run check-arabic-translations
   ```

5. **Unit tests** — when `*.test.ts(x)` or `__tests__/**` changed:
   ```bash
   yarn workspace <workspace> test -- <pattern>
   ```

On FAIL: stop. Do not commit.

## 4. PR scope (before push / `gh pr create`)

Run **after** commit scope passes on the final tree. Required steps:

1. **Prettier (full repo)** — matches CI `Check Prettier`:
   ```bash
   yarn format:check
   ```

2. **Lint (full repo)** — matches CI `Lint`:
   ```bash
   yarn lint
   ```

3. **TypeScript** — for each workspace in `CHANGED_WS`:
   ```bash
   bash scripts/version_vars packages/<workspace>
   yarn workspace <workspace> check-types
   ```
   (`check-types` runs `tsc --noEmit`, same as CI.)

4. **Translations** — for each workspace in `CHANGED_WS`:
   ```bash
   yarn workspace <workspace> run check-translations
   yarn workspace <workspace> run check-arabic-translations
   ```
   Review `git status` after — scanner may rewrite JSON.

5. **Code quality** — matches CI `Check Code Quality`:
   ```bash
   yarn fallow dead-code --circular-deps
   yarn fallow dead-code --unlisted-deps
   ```

6. **Unit tests + coverage** — for each workspace in `CHANGED_WS`:
   ```bash
   NODE_OPTIONS=--max_old_space_size=4096 yarn workspace <workspace> run coverage:summary
   ```

7. **OpenAPI contract** — when `packages/common/src/contract/**` changed (matches
   `contract-openapi.yml` when BE spec available):
   ```bash
   yarn workspace common jest -c jest.contract.config.js --ci
   ```
   CI downloads BE spec from GitHub release; locally use `CONTRACT_FIXTURE_DIR` if you
   have `noon2_core/build/contract-fixtures/openapi.json`. If fixture missing, note in
   chat — CI will still run — but prefer generating the fixture from noon2_core when
   both repos are in scope.

On any FAIL: stop. Do not push or open the PR.

## 5. Full-repo fallback

When scoped checks are inconclusive or the user asks:

```bash
yarn format:check
yarn lint
yarn check-types
yarn check-translations
```

Slow; matches broad CI.

## 6. Report results

Output in chat only (not in PR **Testing**):

- One line per step: `Prettier: PASS|FAIL`, `ESLint: PASS|FAIL`, `check-types (<ws>): PASS|FAIL`, etc.
- **Checks (copy-paste):** exact commands run.
- On FAIL: stop before commit, push, or PR create.

## Existing repo scripts (reference)

| Script                        | Command                   |
| ----------------------------- | ------------------------- |
| Prettier (whole repo)         | `yarn format:check`       |
| Prettier (write)              | `yarn format`             |
| ESLint                        | `yarn lint` or `yarn lint <paths…>` |
| Types (all workspaces)        | `yarn check-types`        |
| Translations (all workspaces) | `yarn check-translations` |
