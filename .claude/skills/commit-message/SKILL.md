---
name: commit-message
description: Create a noon2_core backend commit message from the current working tree, matching repo PR/commit title conventions in AGENTS.md and .github/workflows/pr-wf-title-check.yaml. Use when the user asks for a commit message, conventional commit, or help committing Java/Spring changes in noon2_core.
---

# noon2_core commit message

When invoked, do the following:

1. Inspect the working tree
   - Run `git diff --name-only`
   - If nothing changed, ask the user to make changes first.
   - For modified (non-new) files, review the old-vs-new behavior using `git diff <file>`.
   - For new files, infer intent from the new content (high level), since there is no old state.
   - Do not use file paths as the commit message summary; instead infer the single “thing done” / behavior change.

1b. **Hard CI gate (before real commit / push / PR)**

   Do **not** push and wait for GitHub Actions. Read `.cursor/skills/backend-checks/SKILL.md` and run:

   - **commit** scope before `git commit`
   - **pr** scope before `git push` / `gh pr create`

   On any FAIL: stop. Message-only dry runs may skip — say so in chat.

2. Draft a commit message (noon2_core title format)

   Align with **PR title** rules enforced by CI (same prefixes as merge titles in this repo).

   - Pick the best `type` from:
     `feature`, `bugfix`, `enhancement`, `documentation`, `other`, `ops`, `chore`, `refactor`
     (use the smallest sensible one).
   - Format: `<type>: <subject>`
   - Subject rules:
     - imperative mood
     - no trailing period
     - keep it short (~<= 72 characters soft limit)
   - **Id rules** (when applicable — ask the user if missing):
     - `feature:` — include Notion task id `[GEN-<digits>]` anywhere after the prefix
     - `bugfix:` — end with GitHub issue id `[<digits>]` (open issue in this repo)
     - other types — no trailing id required
   - If the user has not supplied ids, use clear placeholders (`[GEN-XXXX]`, `[XXXX]`) and mention they must be replaced before push/PR.
   - If needed, include a short multi-line body explaining the “what/why” (not the raw diff).
   - Do not mention AI/tools in the commit message.

3. Output the commit message in the chat

   ```
   <final-message>
   ```

4. Keep the open PR title, description in sync (when a PR exists)

   Run this after drafting the message whenever this workflow is used in a real commit flow (not a message-only dry run the user asked to skip).

   - Detect an open PR for the current branch: `gh pr view --json number,title,body`
   - If there is no PR ("pull request not found" / "no pull requests found"): skip and say so briefly.
   - If any other `gh` error: stop and report it.
   - If a PR exists, sync in two parts — **update only when needed**:

     a. **Authored body** (PR workflow sections) — read `.cursor/skills/pr-workflow/SKILL.md` for the shape. Compare the PR body to the full branch vs `main` (`git diff main...HEAD`, plus any staged/unstaged work about to land). Revise `### In one line` and `### Testing` when they are missing, wrong, or clearly stale. Touch optional `## Summary` / `## What changed` / `## Notes` only if those sections already exist and are out of date. Prefer `gh pr edit` with a heredoc or body file. Do not rewrite for polish alone; preserve human edits that still match the branch.

     b. **Change impact** — do **not** invent a separate impact format here, and **do not edit** checked-in `scripts/skills/pr-impact.md`. Use `/pr-impact` for workflow (append/skip), but when drafting or replacing the published block apply the **local house-style length override** from `.cursor/skills/pr-workflow/SKILL.md` (In one line tone: What 1 sentence; ≤3 knock-ons; ≤4 manual checks; one coverage line; ≤2 cross-team):
        - If `<!-- pr-impact-check -->` is **missing**: run `/pr-impact`, then if the appended block is long-form from the checked-in template, immediately rewrite **only** that impact span to the concise house style and `gh pr edit` the body.
        - If the sentinel is **present** and the block still matches the current branch **and** already meets the house-style caps: leave it alone.
        - If the sentinel is **present** but the block is **stale** vs the current diff, or is essay-length: replace **only** that impact span (from the sentinel through the end of `## Change Impact Check`) with a concise house-style block. Do not change `/pr-impact` or `scripts/skills/pr-impact.md`.

   - In chat, report briefly: PR sync skipped / body updated / body unchanged / impact appended / impact refreshed / impact unchanged.

## Type selection hints (backend)

| Type | Typical use |
|------|-------------|
| `feature` | New API, entity, migration, or user-visible capability |
| `bugfix` | Correctness fix tied to a GitHub issue |
| `enhancement` | Improvement to existing behavior without a new feature |
| `refactor` | Structure/readability, no intended behavior change |
| `chore` | Tooling, deps, small maintenance |
| `ops` | Helm, Docker, CI/workflow, deploy config under `ops/` or `.github/` |
| `documentation` | Docs-only |
| `other` | Does not fit above |

## Examples

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
