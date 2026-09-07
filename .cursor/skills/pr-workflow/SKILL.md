---
name: pr-workflow
description: Generate a PR title + body and a ready-to-run `gh pr create` command, applying the current repo's CI title rules (noon2-frontend or noon2_core). Use when the user asks for a PR, PR title, PR description, or a `gh pr create` command.
---

# PR Workflow

Prepares text and commands only — it does **not** push or create the PR.

- Do **not** check whether a PR already exists.
- Do **not** run `gh pr list`, `gh pr view`, or any other `gh` command.

## 0. Resolve the repo profile

Run `git rev-parse --show-toplevel` and match the directory name below. Every
**(profile)** reference in steps 1–6 resolves against this table.

|                    | noon2-frontend                          | noon2_core                                | other repo                                     |
| ------------------ | --------------------------------------- | ----------------------------------------- | ---------------------------------------------- |
| Base branch        | `master`                                | `main`                                     | `git symbolic-ref refs/remotes/origin/HEAD`     |
| Pre-flight         | `quality-checks` skill — **commit** before commit, **pr** before push/PR | `backend-checks` skill — **commit** before commit, **pr** before push/PR | Discover + run same local gate as `commit-workflow` (commit scope already done; **pr** scope = full local CI the project uses before merge if distinct, else re-run typecheck+lint+tests) |
| Title rules        | § Frontend title rules                  | § Backend title rules                      | Conventional-commit prefix, be specific         |
| Body sections      | § Frontend body                         | § Backend body                             | § Frontend body (closest default)               |
| `gh` invocation    | `--body-file` + `--assignee @me`        | `--body-file` + `--assignee @me`           | `--body-file` + `--assignee @me`            |
| Changed-area focus | `packages/*`                            | `src/main/java/**`, `src/main/resources/**` (incl. `messages/`, `db/migration/`), `build.gradle`, `Makefile`, `docker/**`, `.github/workflows/**` | infer from layout |

If the repo is neither, say which profile you are falling back to and continue.

## 1. Collect git context

Run from the repo root. Derive title and body from **all** changes:

- Head branch: `git rev-parse --abbrev-ref HEAD`
- Committed since base *(profile)* — what the PR includes once pushed:
  - `git diff --name-only <base>...HEAD`
  - `git diff --stat <base>...HEAD`
- Staged but not committed: `git diff --name-only --cached HEAD`
- Unstaged: `git diff --name-only HEAD`

Summarize the changed areas using the profile's changed-area focus.

**Hard CI gate:** before drafting **or** creating/pushing a PR, run the profile
pre-flight at **pr** scope (noon skills, or the discovered local gate for other
repos). Report PASS/FAIL **in the chat only** — never in the PR body. On any FAIL:
fix (or stop). **Do not** emit `gh pr create`, and **do not** `git push`, until every
required step is PASS. Noon skills mirror `.github/workflows/pr-wf.yaml` — skipping
them ships known-red PRs.

## 2. Infer what changed, semantically

Old-vs-new aware, across committed + uncommitted:

- **Modified files** — review behavior using the right diff: `git diff <base>...HEAD -- <file>` (committed), `git diff --cached -- <file>` (staged), `git diff -- <file>` (unstaged). Summarize the behavior/intent change, not the raw diff or file paths.
- **New files** — infer the high-level feature/behavior from the content.
- **Deleted files** — summarize the behavior that was removed.

## 3. Draft the title

Both repos enforce titles in `.github/workflows/pr-wf-title-check.yaml`, with
**different rules**. Produce the final title string even if placeholders remain, so
the output is complete.

### Frontend title rules (noon2-frontend)

- Prefix, followed by `:` — one of: `feature`, `enhancement`, `fix`, `refactor`, `build`, `style`, `docs`, `test`, `chore`
- Length **between 20 and 150 characters**.
- `feature:` must **end with** a Notion task id `[GEN-<digits>]`.
- `fix:` must **end with** a GitHub issue id `[<digits>]`.
- Missing id → placeholder `[GEN-XXXX]` / `[XXXX]`, and say it must be replaced.

### Backend title rules (noon2_core)

- Prefix, followed by `:` — one of: `feature`, `bugfix`, `enhancement`, `documentation`, `other`, `ops`, `chore`, `refactor`
- **No** min/max length is enforced — keep it readable and specific anyway.
- `feature:` must include `[GEN-<digits>]` **anywhere after the prefix**.
  Example: `feature: Add GenAI report API [GEN-5092]`
- `bugfix:` must **end with** `[<digits>]` (regex `\[(\d+)\]$`). CI verifies the
  issue exists in this repo, is an issue (not a PR), and is **open** — use a real
  open issue or expect the check to fail.
  Example: `bugfix: Correct null reporter on create [1234]`
- `ops:`, `enhancement:`, `chore:` require a **non-empty body** — CI fails on a blank description.
- Missing id → placeholder `[GEN-XXXX]` / `[XXXX]`, and say it must be replaced.

Note the divergence: frontend uses `fix:`, backend uses `bugfix:`; frontend requires
the `[GEN-…]` id at the **end**, backend allows it anywhere.

## 4. Draft the body

### Frontend body (noon2-frontend)

Default — unless the user explicitly asks for more:

- `### In one line` — **exactly one sentence**, no bullets: plain-language gist for reviewers; skip filler.
- `### Testing` — **manual** verification only.
  - UI / product flows: concrete steps and expected behavior.
  - Include a **manual video snippet** placeholder or link when the change is user-visible.
  - Do **not** list Prettier, ESLint, check-types, check-translations, or other automated output here — CI covers those, and step 1 is for the author.
  - If unknown: short placeholders the author can fill in.

Optional, only when asked: `### Summary` (concise bullets — intent, scope, why),
`### What changed` (behavior- and area-focused bullets, grouped), `### Notes`
(omit unless there is real dependency, rollout, or reviewer context).

### Backend body (noon2_core)

Required: `### In one line` (as above) and `### Testing`.

`### Testing` specifics:

- Tests added/updated/run → commands (e.g. `./gradlew test --tests …`) and PASS/FAIL.
- Note when migrations or Docker-backed tests matter (`make test`, the Flyway job).
- Manual testing → steps, plus screenshots/videos/gists.
- For `ops:` / `enhancement:` / `chore:` titles the body **cannot** be empty — make
  this section substantive, not a bare placeholder.
- No run info → `- Manual testing: <steps + links>`.

Optional, only when asked: `## Summary`, `## What changed` (controllers, services,
entities, Flyway, i18n, tests), `## Notes`.

PR builds run `.github/workflows/pr-wf.yaml`: JDK 25, `make test`, JaCoCo
thresholds, Flyway migration checks against Docker deps. Mention the relevant ones
in `### Testing` when useful.

### Change impact (both repos)

Do **not** draft or embed a Change Impact Check here. After the PR exists (or when
the author asks), run `/pr-impact`, which follows the repo's checked-in
`scripts/skills/pr-impact.md`. **Never edit that file.**

When you write or refresh the impact block, **override its published length** with
this house style — same tone as `### In one line`, not one giant paragraph:

- **What** — one short sentence.
- **Knock-ons** — short bullets, outside-ticket only, or `None.`
- **Manual checks** — checkboxes; skip anything already in `### Testing`.
- **Coverage** — one short line: covered · gaps.
- **Cross-team** — short items, or `None.`
- Labeled lines / tight bullets. No essay sections, no padding.

## 5. Prepare the `gh` command

- Create a **ready-for-review** PR — **never** `--draft`. Reviewers should see it as
  open/ready immediately.
- Always assign the author: append **`--assignee @me`** on every `gh pr create`
  (noon2-frontend, noon2_core, and any other repo). Do not leave PRs unassigned.
- Use **`--body-file`** so markdown newlines render. Do **not** pass the body as
  `--body "...\n..."` — `gh` and many shells keep those as literal backslash-n,
  which renders broken on GitHub.
- Output a short **two-line** recipe to paste and run:
  1. Write the body to a temp file, Fish-safe:
     `printf '%s\n' 'line1' 'line2' ... > /tmp/pr-body.md`
  2. `gh pr create --title "TITLE" --body-file /tmp/pr-body.md --base "BASE" --head "HEAD" --assignee @me`
- Existing PR: `gh pr edit <number> --body-file /tmp/pr-body.md` and, if you are
  not already assignee, `gh pr edit <number> --add-assignee @me`.
- If an existing PR is still draft: `gh pr ready <number>` (do not leave it draft).
- `HEAD` is the current branch from step 1 (or the remote branch the user will push).
- Output the commands only. Do **not** execute them.

## 6. Output

Write exactly this structure in the chat:

- `PR Title: <final-title>`
- `PR Base: <base-branch>`
- `PR Head: <head-branch>`
- `gh pr create command:` — ready to paste/run
- `PR Body (markdown):` — the full body, matching the temp file

## Continuous learning

After drafting, **do not** propose skill edits by default. Only when this run hit a
**repeatable gap** that would help the next PR in that repo:

- A `pr-wf-title-check.yaml` / `pr-wf.yaml` rule not reflected above (prefix, length, id format/placement, open-issue requirement, empty-body types).
- A base-branch or `--body-file` / Fish `printf` gotcha, or a stacked-PR case.
- A manual-testing or video-snippet expectation for a class of change; a Flyway / Docker / JaCoCo note worth reusing.

**When to act:** append **at most 1–2 short bullets**, one line each, under the
matching Learned-patterns heading below. Skip quality-check output, commit-specific
detail, and anything already in steps 3–4.

**How to act:** ask the user before editing this file unless they asked you to
maintain the skill. Add bullets only; do not rewrite the body.

### Learned patterns (noon2-frontend PRs)

<!-- Append repo-specific bullets here after confirmed skill updates. -->

### Learned patterns (noon2_core PRs)

<!-- Append repo-specific bullets here after confirmed skill updates. -->
