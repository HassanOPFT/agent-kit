---
name: backend-checks
description: Run noon2_core PR CI checks locally (Gradle tests, assemble, contract, schema) before commit, push, or opening a PR. Use when commit-workflow, pr-workflow, or execute-plan runs in noon2_core.
---

# Backend checks (noon2_core)

Run from the **noon2_core** repo root (`./gradlew` must exist). Do **not** add scripts
or change `build.gradle` — use existing Gradle tasks only.

Source of truth: `.github/workflows/pr-wf.yaml` and `.github/workflows/pr-wf-title-check.yaml`.

## Hard gate (callers must obey)

`commit-workflow`, `commit-message`, `pr-workflow`, and `execute-plan` **must** run this
skill and treat any FAIL as a stop:

- **Do not** `git commit`, `git push`, or `gh pr create` while a required step is FAIL.
- Fix failures (or report and stop) before continuing.
- **Do not** push and wait for GitHub Actions — run the matching local commands first.

## Scope

| Mode       | When to use                           | Goal                                      |
| ---------- | ------------------------------------- | ----------------------------------------- |
| **commit** | Before `commit-workflow` / committing | Fast feedback on touched code             |
| **pr**     | Before push / `gh pr create`          | Match PR workflow jobs that agents can run locally |

Default base branch for **pr** mode: `main`.

## CI job → local command map

| CI job (pr-wf.yaml)     | Local command (pr scope)                                      | commit scope                         |
| ----------------------- | ------------------------------------------------------------- | ------------------------------------ |
| Unit Tests              | `./gradlew test --build-cache`                                | Focused — see § Commit scope         |
| Integration Tests       | `./gradlew integrationTest --build-cache`                     | Skip unless integration code touched |
| Serial Tests            | `./gradlew serialTest --build-cache`                          | Skip unless serial/concurrency touched |
| API Contract Tests      | `./gradlew apiContractTest --build-cache`                     | Run if `OpenApiContractSpecTest` or contract DTOs touched |
| Build                   | `./gradlew assemble checkApiVersioning --build-cache`         | Skip on commit                       |
| Validate Schema         | Atlas inspect (see § Schema)                                  | Run if `ops/db-migrations/schema.sql` changed |
| Coverage Report         | `./gradlew jacocoTestReport jacocoTestCoverageVerification -x test -x integrationTest -x serialTest -x apiContractTest` | Skip locally unless user asks — needs `.exec` from test jobs |

Title / label gates (no local Gradle): `pr-wf-title-check.yaml`, `pr-wf-bug-critical-label-check.yaml`.

## 1. Collect changed paths

**PR mode** (`BASE=main`):

```bash
BASE=main
CHANGED=$({
  git diff --diff-filter=ACMR --name-only "${BASE}"...HEAD 2>/dev/null
  git diff --diff-filter=ACMR --name-only --cached HEAD
  git diff --diff-filter=ACMR --name-only HEAD
} | sort -u)
```

**Commit mode:** same as PR but only staged + unstaged (omit `BASE...HEAD`).

If `CHANGED` is empty, report "no changed files" and stop.

## 2. Commit scope (fast)

Run before every real commit:

1. For each touched production class under `src/main/java/`, run the matching test class
   when it exists:
   ```bash
   ./gradlew test --tests 'com.noon.noon2.service.hybrid.PhysicalClassroomServiceImplTest' --build-cache
   ```
   Derive `<Fqcn>Test` from the edited class name. If several classes changed, run one
   `--tests` per class (or one combined `./gradlew test --tests '…Test' --tests '…Test'`).

2. If no focused test exists, run `./gradlew test --build-cache` for that module's
   package prefix when the change is non-trivial:
   ```bash
   ./gradlew test --tests 'com.noon.noon2.service.hybrid.*' --build-cache
   ```

3. If `src/test/java/com/noon/noon2/contract/` or `RESPONSE_ROOTS` / OpenAPI contract
   files changed, also run:
   ```bash
   ./gradlew apiContractTest --build-cache
   ```

On FAIL: stop. Do not commit.

## 3. PR scope (before push / `gh pr create`)

Run **after** commit scope passes on the final tree. Order:

1. **Unit tests** (required):
   ```bash
   ./gradlew test --build-cache
   ```

2. **Integration tests** (required when `CHANGED` touches `src/main/java/**`,
   `src/test/java/**` integration packages, or `docker/**`):
   ```bash
   ./gradlew integrationTest --build-cache
   ```
   When unsure, run it — CI always does.

3. **Serial tests** (required when change touches locking, WebSocket fanout, or
   `serialTest` sources; otherwise still run before PR — CI always does):
   ```bash
   ./gradlew serialTest --build-cache
   ```

4. **API contract tests** (required when REST response DTOs or
   `OpenApiContractSpecTest.java` / `contractRegistry` on FE side changed):
   ```bash
   ./gradlew apiContractTest --build-cache
   ```
   When BE DTOs changed, run even if only Java changed.

5. **Assemble + API versioning** (required before PR):
   ```bash
   ./gradlew assemble checkApiVersioning --build-cache
   ```

6. **Schema validate** (required when `ops/db-migrations/schema.sql` changed):
   ```bash
   atlas schema inspect \
     --url "file://ops/db-migrations/schema.sql" \
     --dev-url "docker+mysql://_/mysql:8.0/dev" \
     --format '{{ sql . }}' > /dev/null
   ```
   Skip only if Atlas is not installed — say so and note CI will still gate.

## 4. Report results

Output in chat only (not in PR body):

- One line per step: `test: PASS|FAIL`, `integrationTest: PASS|FAIL`, etc.
- **Checks (copy-paste):** exact commands run.
- On any FAIL in a **required** step: stop — do not push or open the PR.

## Existing commands (reference)

| Goal              | Command                                              |
| ----------------- | ---------------------------------------------------- |
| Unit tests only   | `./gradlew test --build-cache`                       |
| Makefile shortcut | `make test` (= `./gradlew clean test` — slower)      |
| Full PR parity    | Run all steps in § PR scope                          |

CI runs jobs in parallel; locally run sequentially. That is fine — same Gradle tasks.
