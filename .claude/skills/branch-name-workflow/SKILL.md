---
name: branch-name-workflow
description: Infer branch intent from user request context and current git changes, then propose concise branch names. Use when the user asks for branch naming, branch suggestions, or intent-based branch names.
---

When invoked, do the following (propose names only; do not create/switch branches unless asked):

1. Collect intent from context + git
   - Read the user request/chat context to understand what is being built/fixed.
   - Run:
     - `git diff --name-only`
     - `git diff --stat`
   - If needed, inspect key files with `git diff -- <file>` to infer behavior-level intent.

2. Classify the change
   - Choose one type: `feature`, `fix`, `refactor`, `chore`, `docs`, `test`, `hotfix`.
   - Identify a short scope (domain/area) and short action phrase.

3. Generate branch names
   - Preferred format: `<type>/<scope>-<intent>`
   - If ticket exists, support: `<type>/<ticket>-<scope>-<intent>`
   - Rules:
     - lowercase only
     - kebab-case words
     - no spaces/underscores
     - keep concise (target <= 55 chars)
     - avoid file-path wording and implementation noise

4. Output (chat response)
   - `Intent: <one-line intent>`
   - `Recommended: <best branch name>`
   - `Alternatives:`
     - `<option-2>`
     - `<option-3>`
     - `<option-4>` (optional)
