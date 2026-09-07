---
name: commit-workflow
description: Create a conventional commit message from the current working tree, using the current repo's type vocabulary (noon2-frontend or noon2_core). Use when the user asks for a commit message, wants help drafting commits, or invokes commit-workflow.
---

# Commit Workflow

## 0. Resolve the repo profile

Run `git rev-parse --show-toplevel` and match the directory name:

|                | noon2-frontend                          | noon2_core                                                                        | other repo                              |
| -------------- | --------------------------------------- | --------------------------------------------------------------------------------- | --------------------------------------- |
| Types          | `fix`, `feat`, `chore`, `test`, `docs`  | `feature`, `bugfix`, `enhancement`, `documentation`, `other`, `ops`, `chore`, `refactor` | `fix`, `feat`, `chore`, `test`, `docs`  |
| Trailing ids   | none                                    | required for `feature:` / `bugfix:` — see § Backend ids                            | none                                     |
| PR sync step   | skip                                    | step 4 applies                                                                     | skip                                     |

The backend types deliberately match that repo's **PR title** rules (CI enforces the
same vocabulary on merge titles), which is why they differ from plain Conventional Commits.

## 1. Inspect the working tree

No staging yet.

- Run `git diff --name-only`. If nothing changed, ask the user to make changes first.
- **Modified files** — review old-vs-new behavior with `git diff <file>`.
- **New files** — infer intent from the content, since there is no old state.
- Never use file paths as the summary. Infer the single "thing done" / behavior change.

## 1b. Hard CI gate (required before commit / push / PR)

**Do not push and wait for GitHub Actions.** Run the repo's local CI checks first.

| Repo | Skill | Scope |
|------|-------|-------|
| **noon2-frontend** | `quality-checks` | **commit** before `git commit`; **pr** before `git push` / `gh pr create` |
| **noon2_core** | `backend-checks` | **commit** before `git commit`; **pr** before `git push` / `gh pr create` |
| other | **Discover** then run (below) | same hard stop on FAIL |

### Other repo — discover local gate

Do not hardcode per-repo quirks or eslint/husky rule ids in agent-config. For any
repo that is not noon2-frontend / noon2_core:

1. Read `AGENTS.md` / `README*` / project docs for the check commands.
2. Else inspect `package.json` scripts, `Makefile`, Gradle, husky hooks, and
   `.github/workflows` — prefer `typecheck` / `lint` / `test` / `check` (or what
   AGENTS.md names).
3. Run the discovered **commit**-scope checks before `git commit`.
4. On FAIL → fix and re-run. Do not commit until PASS.

On any FAIL: fix (or stop). **Do not** `git commit`, `git push`, or `gh pr create` until every
**required** step for that scope is PASS.

Message-only dry runs the user explicitly asked to skip may omit the gate — say so in chat.
Any real commit/push/PR must pass the gate.

## 2. Draft the message

- Pick the **smallest sensible** type from the profile's vocabulary.
- Format: `<type>: <subject>`
- Subject: imperative mood, no trailing period, short (~72 characters soft limit).
- Optional short multi-line body explaining **what/why** — not the raw diff.
- Never mention AI or tooling in the message.

### Backend ids (noon2_core)

Ask the user if an id is missing:

- `feature:` — include a Notion task id `[GEN-<digits>]` anywhere after the prefix.
- `bugfix:` — **end with** a GitHub issue id `[<digits>]`, an open issue in this repo.
- All other types — no trailing id required.

With no id supplied, use `[GEN-XXXX]` / `[XXXX]` and say it must be replaced before push/PR.

### Backend type selection hints

| Type            | Typical use                                                     |
| --------------- | --------------------------------------------------------------- |
| `feature`       | New API, entity, migration, or user-visible capability           |
| `bugfix`        | Correctness fix tied to a GitHub issue                           |
| `enhancement`   | Improvement to existing behavior without a new feature           |
| `refactor`      | Structure/readability, no intended behavior change               |
| `chore`         | Tooling, deps, small maintenance                                 |
| `ops`           | Helm, Docker, CI/workflow, deploy config under `ops/` or `.github/` |
| `documentation` | Docs-only                                                        |
| `other`         | Does not fit above                                               |

## 3. Output

Write only the message in the chat:

```
<final-message>
```

## 4. Keep an open PR in sync — noon2_core only

Run this after drafting whenever the workflow is used in a **real commit flow**, not
a message-only dry run the user asked to skip.

- Detect an open PR for the branch: `gh pr view --json number,title,body`
- No PR ("pull request not found" / "no pull requests found") → skip, say so briefly.
- Any other `gh` error → stop and report it.

If a PR exists, sync in two parts, **updating only when needed**:

**a. Authored body.** Read the `pr-workflow` skill for the shape. Compare the PR body
to the full branch vs `main` (`git diff main...HEAD`, plus staged/unstaged work about
to land). Revise `### In one line` and `### Testing` when missing, wrong, or clearly
stale. Touch optional `## Summary` / `## What changed` / `## Notes` only if they
already exist and are out of date. Prefer `gh pr edit` with a body file. Do not
rewrite for polish alone — preserve human edits that still match the branch.

**b. Change impact.** Do **not** invent a separate impact format, and do **not** edit
the checked-in `scripts/skills/pr-impact.md`. Use `/pr-impact` for workflow
(append/skip), but apply the house-style length override from the `pr-workflow`
skill: What = 1 sentence; ≤3 knock-ons; ≤4 manual checks; one coverage line; ≤2 cross-team.

- Sentinel `<!-- pr-impact-check -->` **missing** → run `/pr-impact`, then if the appended block is long-form from the template, immediately rewrite **only** that impact span to house style and `gh pr edit` the body.
- Sentinel **present**, block matches the current branch **and** meets the caps → leave it alone.
- Sentinel **present** but stale vs the current diff, or essay-length → replace **only** that span, from the sentinel through the end of `## Change Impact Check`.

Report briefly in chat: PR sync skipped / body updated / body unchanged / impact
appended / impact refreshed / impact unchanged.

## Examples (noon2_core)

```
feature: add misclassification genai report type [GEN-5092]
```

```
bugfix: reject null report type on genai report create [1234]
```

```
enhancement: trim feature field on genai report create
```

```
chore: add flyway migration for genai report enum
```
