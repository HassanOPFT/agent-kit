---
name: "pubnoon-activity-creator"
description: "Use when creating or extending Noon classroom activities that should follow PubNoon gameplay patterns, reuse the noon2-activity-competition-template integrations, apply Nolt.diy prompt guardrails, and keep Noon2 frontend question UX."
---

# PubNoon Activity Creator

Use this skill when the activity should feel like PubNoon while staying aligned with Noon platform contracts.

## Source Repos

This skill expects the following source repos to exist somewhere in the local workspace:
- `pubnoon` — standalone checkout, or nested at `noon2-activities/activities/pubnoon`
- `nolt.diy`
- `noon2-activity-competition-template` — standalone checkout, or nested at `noon2-activities/activities/noon-competition-activity-racecars-v2` (the racecars-v2 activity carries the full competition-template integration contract: `questionsService`, `useQuestions`, `questionBank`, etc.)
- `noon2-frontend`
- `noon2_core`

Run this first:

```bash
bash scripts/discover_noon_repos.sh "$PWD"
```

That script prints the repo roots used throughout the references:
- `PUBNOON_ROOT`
- `COMP_TEMPLATE_ROOT`
- `NOLT_DIY_ROOT`
- `NOON2_FRONTEND_ROOT`
- `NOON2_CORE_ROOT`

If one or more repos are missing, say exactly which ones are unavailable and continue with the closest available source.

## Outcome

Build or revise a Noon web activity that:
- starts from the competition template
- borrows gameplay structure from PubNoon where useful
- follows Nolt.diy prompt and platform rules
- presents questions in the same interaction family as Noon2 frontend

## First Pass

1. Run `bash scripts/discover_noon_repos.sh "$PWD"` and resolve the repo roots.
2. Read [references/platform-integrations.md](references/platform-integrations.md).
3. Read only the reference file that matches the task:
   - gameplay, role split, reducer, multiplayer loop: [references/pubnoon-patterns.md](references/pubnoon-patterns.md)
   - question layout, choice states, submit and review flow: [references/noon2-question-style.md](references/noon2-question-style.md)
   - exact files to inspect next: [references/repo-map.md](references/repo-map.md)
4. Decide the question-loading mode before editing:
   - embedded slide activity: `sessionSlideId` flow from the competition template
   - runtime Nolt activity: `noltId` flow from PubNoon

## Non-Negotiables

- Treat the competition template platform files as locked unless the user explicitly asks for platform-level changes:
  - `src/services/`
  - `src/hooks/useNoonAuth.js`
  - `src/hooks/useQuestions.js`
  - `src/config/envConfig.js`
  - `src/data/questionBank.js`
- Keep local preview compatible with Nolt and WebContainer: prefer empty or relative API base URLs and call `/noon2-core/...`.
- Wire auth, question loading, answer submission, telemetry, and multiplayer before polishing visuals.
- Keep distinct role-based surfaces when the activity is multiplayer or teacher-presented.
- Design for embedded `960x540` behavior with contained scrolling.

## Prompt Seed

When another model or agent needs build instructions, reuse the constraint language from the Nolt platform prompt files described in [references/platform-integrations.md](references/platform-integrations.md).

Use them as guardrails, not as a dumping ground for boilerplate. The important rules are: locked platform files, relative `/noon2-core/*` requests for preview, role-based views, and wiring the platform services in the app shell.

## Build Order

1. Scaffold or branch from the competition template.
2. Preserve the integration contract from [references/platform-integrations.md](references/platform-integrations.md).
3. Port or adapt PubNoon patterns selectively:
   - reducer-driven shared state
   - presenter, captain, and member split when needed
   - message types and host-driven phase transitions for multiplayer rounds
4. Port Noon2 question UX selectively:
   - question container framing
   - student question header and body
   - stacked scrolling choices
   - `selected`, `unselected`, `correct`, and `incorrect` states
   - explicit submit or free-flow navigation footer
   - localized `A/B/C/D` or `A/B/C/D` alternatives for the target locale
5. Add activity-specific mechanics last.

## Question-Loading Decision

Use the correct backend path for the activity type.

- **Embedded activity slide**
  - Use the competition template flow from `useQuestions()` and `questionsService`
  - Endpoint:
    `GET /noon2-core/courses/{courseId}/sessions/{courseSessionId}/slides/{sessionSlideId}/activity`

- **PubNoon or Nolt runtime activity**
  - Use the PubNoon flow keyed by `noltId`
  - Endpoint:
    `GET /noon2-core/course-sessions/{courseSessionId}/nolt-activities/{noltId}/runtime-questions`

If the task also needs teacher-side question assignment for the Nolt activity bank, consult [references/platform-integrations.md](references/platform-integrations.md).

## Visual Guidance

Do not copy PubNoon's dark battle theme unless the request asks for it.

For question presentation, follow Noon2 frontend structure and interaction states rather than PubNoon's custom `QuestionCard.jsx` styling. PubNoon is the gameplay reference. Noon2 frontend is the question UX reference.

## Validation Checklist

- `useNoonAuth()` supplies `token`, `user`, `sessionDetails`, `team`, and `defaultHeaders`
- `useQuestions()` returns configured questions or a sane fallback
- MCQ submissions call `answerService.submitAnswer(...)`
- telemetry tracks activity start, activity end, and point-level interactions
- multiplayer connects only when the activity actually needs shared state
- student and presenter or teacher views diverge correctly
- question choices expose clear `selected`, `unselected`, `correct`, and `incorrect` states
- local preview keeps relative `/noon2-core/*` requests
