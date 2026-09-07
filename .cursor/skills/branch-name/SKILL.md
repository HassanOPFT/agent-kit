---
name: branch-name
description: Suggest a git branch name for noon2_core backend work from current changes or described intent. Use when the user asks for a branch name, naming a branch, or starting work before opening a PR.
---

# noon2_core branch name

When invoked, do the following:

1. Understand the work
   - If there are local changes: run `git diff --name-only` and infer the single behavior change (same spirit as **commit-message** — behavior, not file paths).
   - If the user described the task, use that instead.
   - If unclear, ask one short question (e.g. Notion id or GitHub issue number).

2. Pick a prefix (first path segment)

   Match how this repo names branches today:

   | Prefix | Use when |
   |--------|----------|
   | `feature/` | New capability, API, migration, or product-facing change (most common) |
   | `fix/` | Bugfix tied to a GitHub issue |
   | `chore/` | Tooling, tests-only hygiene, deps, refactors with no product change |
   | `feat/` | Optional shorthand; often paired with a ticket id |

   Do **not** suggest `release/YYYY.MM.DD` — those are created by automation from `main`, not for feature work.

3. Build the branch name

   - Format: `<prefix>/<slug>` or `<prefix>/GEN-<digits>` when the user supplies a Notion id.
   - Slug rules:
     - lowercase
     - words separated by `-` (kebab-case)
     - short and specific (aim ~3–6 words)
     - ASCII letters, digits, and hyphens only
     - no trailing slash, no spaces, no underscores
   - Examples from this repo: `feature/genai-report-api`, `feat/GEN-5092`, `fix/profile-update-latency`, `chore/connection-health-service-tests`

4. Output (write only in the chat)

   ```
   <final-branch-name>
   ```

   If a Notion or issue id would help but is missing, output the best name anyway and one line: which id to add if they use `feat/GEN-…` or `fix/<issue>-…` style.

## Examples

```
feature/genai-report-misclassification-type
```

```
feat/GEN-5092
```

```
fix/1234-genai-report-null-type
```
