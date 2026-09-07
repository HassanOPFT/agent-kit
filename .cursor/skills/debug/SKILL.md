---
name: debug
description: >-
  Investigate bugs and unexpected behavior across noon2-frontend, noon2_core,
  and related tools without changing code unless asked. Pulls evidence from
  code, Datadog, MySQL, Slack, and API repro as needed; states ownership and
  confidence plainly. Use when the user says debug, investigate, triage, figure
  out why, root cause, or attaches this skill with a bug/symptom/issue.
---

# Debug

Investigate first. **Do not edit code, open PRs, commit, or “just fix it”** unless
the user explicitly asks to apply a fix after the investigation.

Tone: concise, proactive, evidence-led. Prefer gathering the next useful signal
over asking the user for context you can pull yourself.

## On start

1. Load both Bug Agent context packs (do not reinvent triage):
   - `noon2_core/.github/bug-agent/context/{debugging-playbook,service-map,architecture}.md`
   - `noon2-frontend/.github/bug-agent/context/{debugging-playbook,service-map,architecture}.md`
2. Skim [reference.md](reference.md) for Datadog service names, env map, and
   composed skills.
3. If Datadog MCP tools are missing, run the `ddsetup` skill before concluding
   Datadog is unavailable.

## Do

1. **Frame the symptom** — env, app/role/platform, time window, IDs
   (profile/user/room/session/request/trace). If critical fields are missing,
   name them once; keep investigating with what you have.
2. **Classify** — API, classroom/WS, data, job/async, external dependency, or
   FE-only UI. Prefer the playbook path that matches.
3. **Pull evidence proactively** (only what the class needs; stop when ownership
   is clear enough):
   - **Code** — both FE and core before assigning ownership; use service maps
     for first-hop packages/controllers.
   - **Datadog** — logs/RUM/traces/error tracking via MCP; query by
     `service:` + `env:` + IDs/time; prefer **links + short summaries**, not
     raw dumps.
   - **Slack** — if a thread/link is present, read it via Slack MCP for IDs
     and repro facts only (no private URLs/file IDs in output).
   - **DB** — read-only via **noon-mysql** (VPN via **pritunl-vpn** for remote);
     default `staging`/`local`; **prod only when the user asks**. Remote reads use
     native `mysql-client` — do not start Docker Desktop/compose for them;
     **docker-deps** is for local MySQL only.
   - **Repro** — optional **api-test-scripts** / local stack skills to confirm
     a branch; do not claim tests ran unless you ran them.
4. **Separate** confirmed facts from hypotheses. Weak evidence → lower
   confidence and list what would confirm/reject.
5. **Stop at the investigation** when the user only asked to debug/triage.
   Offer a concrete fix path; wait for explicit go-ahead to change code.

## Guardrails

- Ownership ∈ `frontend | core | cross-repo | infrastructure | unknown` — from
  **evidence**, not from which repo the ticket lives in.
- Confidence ∈ `high | medium | low`. `high` needs code and/or observability
  evidence. No high core ownership without core/backend evidence.
- Classroom/live bugs: always check FE RUM **and** `noon2-core-ws` (and pod/
  deploy timing) before blaming one side.
- Soft-fail if Datadog/Slack/DB is down — continue repo-only and mark confidence
  lower.
- Never print secrets, `.env` values, tokens, or huge log/session payloads.
- Do not invent parallel playbooks; extend the Bug Agent docs when stuck.

## Output

Lead with one short verdict paragraph, then this structure (omit empty sections
only when truly N/A; write `None found` for evidence sources you checked):

```
### Verdict
One paragraph: what broke, where, how sure.

### Ownership
frontend | core | cross-repo | infrastructure | unknown
Confidence: high | medium | low — one-line why.

### Likely cause
What and where (file/endpoint/job/service pointers). Cause confidence.

### Evidence
- Confirmed facts: …
- Frontend: … | Core: … | Datadog: … | Slack: … | DB: …
- Competing hypotheses: …
- Conflicting / missing: …

### Next steps
Numbered, smallest next checks (or fix plan if asked). Do not claim work done.
```

Keep it skim-friendly. No filler. Point to paths and Datadog links; do not paste walls of logs.
