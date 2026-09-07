---
name: execute-plan
description: >-
  Orchestrate a locked task plan end-to-end across primary known repos
  (noon2-frontend / noon2_core / api-test-scripts / playground) and other
  workspace repos when named: implement with language clean-code skills,
  loop clean-code until clear, write API tests for backend (skip auto-run on
  critical externals), open PRs, and auto-babysit. Use when the user says
  execute-plan, execute this plan, run the plan, or invokes the execute-plan
  agent/command.
---

# Execute plan

Automate delivery of a **locked** plan. Do not wait on the human unless production
data/secrets/irreversible ops are at risk. Skip critical external live calls;
leave a runbook; keep going through PR + babysit.

**Preferred entry:** the `execute-plan` agent (`.claude/agents/execute-plan.md` /
`.cursor/agents/execute-plan.md`) or `/execute-plan`. This skill is the contract
that agent must follow.

## Inputs

- A locked plan (bullets or one-liner from `task-plan`) and target repos.
- Optional GitHub/Notion ids for BE PR titles (`bugfix: … [9251]`, `feature: … [GEN-…]`).

If the plan is not locked, run `task-plan` first and stop.

## Non-negotiables

- **Proactive:** branch, implement, test what is safe, commit, push, open PR, babysit — without asking permission for each step.
- **Playground:** use `playground/.env` and non-prod keys freely; no permission prompt.
- **Critical external** (Google Workspace/Directory, payments, prod SMS/email providers, live prod writes): **never auto-run** live calls. Still write `TEST_PLAN.md` + script + human runbook. **Do not stop the pipeline.**
- **Block only for:** prod credentials, irreversible prod migration/data destroy, or security scope the human must decide.
- **Gaps:** list under `## Human follow-ups` in each PR body; continue.
- **Backward compatible by default:** API, DTO, schema, and client changes must keep older FE/BE working in either deploy order (see `clean-code` → Backward compatibility). Prefer additive optional fields, nullable columns, and dual-read for storage format changes. If a break is unavoidable, version/flag it and document the cutover in the PR—do not ship a silent break.

## Repo map

| Path | Role |
|------|------|
| `noon2-frontend/` | FE — base `master` |
| `noon2_core/` | BE — base `main` |
| `api-test-scripts/` | Live API suites (skill `api-test-scripts` / Cursor `backend-api-test-scripts`) |
| `playground/` | Non-prod env, fixtures, helpers |

Detect repo with `git rev-parse --show-toplevel`. Multi-repo plans → one branch/PR per repo (unless user said otherwise).

### Other / unknown repos (discover, don’t hardcode)

- If the user names a path (e.g. “only nolt”), that **authorizes that repo** even when it is not in the table. Do not treat it as out of scope.
- After `git rev-parse --show-toplevel`, if the repo is not `noon2-frontend` / `noon2_core` (and not only `api-test-scripts` / `playground` helpers), **discover** conventions from the project:
  1. Read `AGENTS.md` / `README*` / `.claude/skills` / project docs for commands and conventions.
  2. Default branch: `git symbolic-ref refs/remotes/origin/HEAD` (fallback `main`).
  3. Local CI gate from `package.json` / `Makefile` / Gradle / husky / `.github/workflows` — prefer scripts named like `typecheck`, `lint`, `test`, `check`, or whatever `AGENTS.md` says.
  4. Commit/PR title style from recent `git log` + any CI title-check workflow.
- **Hard gate:** run discovered checks at **commit** scope before commit and **pr** scope before push / `gh pr create`. On FAIL → fix; do not push.
- Do **not** memorize project-specific eslint/husky rule ids in agent-config. Run the project’s lint/hooks and fix what they report.

## Language / quality skills (mandatory)

Use the real skill folder names under `.claude/skills/`:

| Touch | While coding | After coding (loop) |
|-------|----------------|---------------------|
| `.ts` / `.tsx` | `clean-typescript-style` | same + `clean-code` |
| Java in `noon2_core` | `google-java-style` | same + `clean-code` |
| Other | `clean-code` | `clean-code` |
| FE before commit / push / PR | `quality-checks` (**hard gate**) | commit scope → commit; pr scope → push/PR |
| BE before commit / push / PR | `backend-checks` (**hard gate**) | commit scope → commit; pr scope → push/PR |
| Other named repo before commit / push / PR | **Discover** local gate (see above) (**hard gate**) | commit scope → commit; pr scope → push/PR |

### Clean-code loop

1. Diff all changes for this plan.
2. Apply the matching skill(s); fix every actionable finding.
3. Re-diff and re-run the skill(s).
4. Repeat until a full pass reports **no actionable issues** (cap **5** passes; then list leftovers in PR follow-ups and continue).

Do not expand scope during the loop.

## Pipeline

### 1. Orient

- Sync bases (`master` / `main`) if needed; propose names with `branch-name-workflow`, then **create/switch** those branches.
- List plan bullets as a working checklist.
- **New worktree / checkout path:** after `git worktree add` (or clone), call
  `move_agent_to_root` on that absolute path. If it fails (“Could not resolve
  workspace” / path not registered yet), **do not stall** — keep going with Shell
  `working_directory` and subagent cwd on that path; retry `move_agent_to_root`
  once the folder is registered. Never edit a sibling worktree the plan did not
  name (isolate branches).
- **Owning branch = no edit approvals:** the plan’s worktree owns the work. Do
  not wait on Cursor Approve for edits there. Prefer `move_agent_to_root` first;
  if Write/StrReplace would still prompt (path outside open workspace roots),
  apply via Shell with `required_permissions: ["all"]`. Launch **one** babysit
  subagent per PR and pass that absolute worktree path (see `babysit` → Owning
  worktree).

### 2. Implement

- Smallest change that satisfies the plan; prefer extend over invent.
- FE ↔ BE contracts: keep Zod/DTOs aligned in the same effort when both repos are in scope.
- Before coding wire/schema changes, apply `clean-code` **Backward compatibility**: additive optional fields, nullable columns, either-side deploy order. If incompatible, stop and version/flag + document—do not proceed as a silent break.

### 3. Clean-code loop

- Run the loop above on **all** touched files.

### 4. Backend API tests (`noon2_core` controller/API changes)

Follow `api-test-scripts` (and `api-test-scripts/AGENTS.md`):

1. Write/update `api-test-scripts/<feature>/TEST_PLAN.md`.
2. Generate `test_*.sh` + `.env.example`.
3. Classify:

| Class | Action |
|-------|--------|
| Safe local/docker (no critical external) | Run the script; fix failures; re-enter clean-code loop if code changed |
| Critical external | **Do not run.** Commit plan+script; add **Human runbook** (env, command, expected); continue |

Seeds that mutate DB: document; apply only with existing skill gates (`NOON_MYSQL_APPLY_OK=1`) when non-prod and already aligned — do not block the PR on seed apply.

### 5. CI gate + commit + push

Run local checks that mirror GitHub Actions **before** push — do not push and wait for CI.

- **noon2-frontend:** `quality-checks` **commit** scope → PASS → commit → `quality-checks`
  **pr** scope → PASS → push.
- **noon2_core:** `backend-checks` **commit** scope → PASS → commit → `backend-checks`
  **pr** scope → PASS → push.
- **Other named repo:** discover the local gate (Repo map → Other / unknown repos) →
  **commit** scope → PASS → commit → **pr** scope → PASS → push. Do not hardcode
  per-repo quirks in agent-config.
- Then `commit-workflow` for message shape; agent **does** `git add` / `git commit` /
  `git push -u`.
- BE ids: use known issue/Notion ids; if CI requires an id and none exists, use best-fit
  type and note the gap — do not stall unless push is impossible.

### 6. Open PRs

- Re-run the repo pre-flight skill at **pr** scope if anything changed after push prep;
  **block** `gh pr create` until PASS.
- Open the PR with `pr-workflow` (ready-for-review, **never** `--draft`, always
  `--assignee @me`); agent **does** create it (`gh pr create`), not draft-only text.
- One PR per repo. Body must include: plan summary, test notes, **Human follow-ups** (critical external runbook, missing ids, etc.).
- Link related issues (e.g. `#9251`).

### 7. Babysit (automatic)

- Immediately **delegate** `babysit` / `pr-babysit` to a **background subagent** for each
  opened PR (see **Long-running work → subagents** below). Do not block the parent turn
  on CI/Rabbit poll loops.
- Do not wait for the human to invoke babysit.
- Do not merge unless the user explicitly asked to merge.

### 8. Hand-off

Short status: PRs + URLs, what ran, what was skipped (critical external), human follow-ups.

Then add **`## Agent / skill improvement suggestions`** (suggestions only — see below).

## Agent / skill improvement suggestions (mandatory at hand-off)

After the run, report friction that is worth encoding for the next run. Prefer durable
guidance over one-off bugs.

**Do:**

- List concrete struggles: missing skill steps, wrong defaults, unclear repo rules,
  repeated clean-code thrash, API-test gaps, babysit/PR/commit friction, AGENTS.md /
  agent-config blind spots.
- Suggest **what** to add or change, and **where** (skill name, agent file, command,
  or config under `agent-config` / repo `AGENTS.md` / `.cursor` / `.claude`).
- Keep each item short: problem → proposed addition → target file/skill.
- Skip noise: one-off typos, transient CI flakes, or issues already covered well.

**Do not:**

- Edit, create, or patch any agent, skill, command, or config file for these ideas.
- Open a PR or commit that only updates agent-config from this section.
- Block delivery waiting for the human to accept suggestions.

Omit the section only when the run had no durable friction worth recording.

## Long-running work → subagents (mandatory)

**Do not block the parent agent on waits.** Delegate work that mostly sleeps, polls, or
runs for many minutes. The parent continues implementation, hand-off, or the next repo.

| Work | Delegate? | How |
|------|-----------|-----|
| Babysit (CI + CodeRabbit loops) | **Yes** | **Exactly one** background subagent per PR; pass owning worktree path; parent reports PR URL + “babysit running” |
| Full test suite / `./gradlew test` / `yarn test` (> ~2 min) | **Yes** when parent has other work | Subagent or parallel shell; parent checks result, does not spin |
| CI poll loops (`sleep` + `gh pr checks` every 30–45s) | **Yes** | Never in parent turn; babysit subagent only |
| Broad repo exploration (many dirs/patterns) | **Yes** | `explore` subagent; parent gets summary |
| Local typecheck/lint for one commit | No | Run inline before commit |
| Single focused unit test file | No | Run inline |

**Subagent contract:** pass repo path, PR URL/number, branch, babysit skill path, and
success criteria (“Rabbit approved + all CI green, do not merge”). Parent does not
re-poll unless the subagent errors or the user asks for status.

## Scale-at-design compass (plan + implement)

Before locking or building a feature, run the **scale compass** from `clean-code` →
**Design at scale**. During `task-plan`, call out scale risk in the one-line plan when
non-trivial. During implement, **stop and amend the plan** (one short note + continue)
if the chosen shape would become a request-path bottleneck or break under 10× load.

Red flags to escalate in the PR or `Human follow-ups`:

- Heavy CPU/I/O on the synchronous request thread (transform + upload + persist in one handler).
- Unbounded in-memory buffers or full-table scans in hot paths.
- N+1 external calls; missing pagination/backpressure on list endpoints.
- “Convenience now” that forces every client through one server choke point when direct-to-store
  or async worker patterns are standard for that workload.

Prefer industry-standard offload: **async jobs**, **direct client upload** (presigned URLs /
signed POST), **queues + workers**, **event-driven side effects**, **streaming/chunking**,
**pagination**, **caching with clear invalidation**. Match the pattern to the workload;
do not copy one example blindly.

## Anti-patterns

- Re-planning a locked plan unless implementation proves it wrong (then one short amend + continue).
- Stopping because Google/external tests were skipped.
- Asking “should I commit/PR/babysit?” — yes, do it.
- **Blocking the parent turn** on babysit, long CI polls, or multi-minute test suites.
- Force-push, prod deploys, or bypassing hooks.
- Silently applying agent/skill/config “improvements” from the hand-off section.
