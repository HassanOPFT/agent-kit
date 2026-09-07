---
name: add-mock-noon2-core-activities
description: Add .mock-noon2-core into one or more activities, starting from main on a fresh branch, then commit, push, and open a draft PR. Use when the user gives one or more activity names to update.
disable-model-invocation: true
---
# Add Mock Noon2 Core Activities

## Inputs
- Activity name(s) to update (for example: `esl-level-1-theme-3` or `activities/eos-esl-level-1-standalone`)

## Steps
1. Before searching, branching, or any other action, checkout `main` and run `git pull` to sync latest changes.
2. Verify repo status after pull.
3. Create a new branch from `main` with a clear `chore/add-mock-noon2-core-<activity-name>` name.
4. Copy `.mock-noon2-core` from a known source activity (default: `activities/esl-writing-level-2/.mock-noon2-core`) into each target activity path under `activities/<activity-name>/`. Strip a leading `activities/` from the input if present.
5. Confirm the copied files exist:
   - `.mock-noon2-core/builders.js`
   - `.mock-noon2-core/harnessState.js`
   - `.mock-noon2-core/vitePlugin.js`
6. Run a quick status check and report changed files.
7. **Commit, push, and create the draft PR** (do not leave this to the user):
   - `git add activities/<activity-name>/.mock-noon2-core/`
   - `git commit -m "chore: add mock noon2 core to <activity-name>"`
   - `git push -u origin <branch>`
   - `gh pr create --draft --base main --title "chore: add mock noon2 core to <activity-name>" --body "Adds \`.mock-noon2-core\` for local dev harness."`
8. Share the draft PR URL in the response.

## Output Style
- Keep output concise and direct.
- Use minimal PR title/body.
- If a target activity path does not exist, stop and ask for the correct name.
- End with the draft PR link; do not list manual git/gh commands unless a step failed.
