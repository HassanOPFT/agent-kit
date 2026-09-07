# Platform Integrations

Use this file for the concrete Noon platform contract.

All paths below are expressed in terms of the repo roots returned by:

```bash
bash scripts/discover_noon_repos.sh "$PWD"
```

## Prompt Sources

Primary source files:
- `${NOLT_DIY_ROOT}/app/lib/common/prompts/noon-platform-instructions.ts`
- `${COMP_TEMPLATE_ROOT}/.bolt/prompt`
- `${NOLT_DIY_ROOT}/app/utils/selectStarterTemplate.ts`

Those files establish the operational rules used by Nolt when it scaffolds Noon activities.

## Locked Contract

From the Nolt prompt and the competition template, treat these paths as platform-owned unless the user explicitly asks for platform changes:
- `${COMP_TEMPLATE_ROOT}/src/services/embeddedAuth.js`
- `${COMP_TEMPLATE_ROOT}/src/services/telemetry.js`
- `${COMP_TEMPLATE_ROOT}/src/services/MultiplayerService.js`
- `${COMP_TEMPLATE_ROOT}/src/services/auth.js`
- `${COMP_TEMPLATE_ROOT}/src/services/sessionContext.js`
- `${COMP_TEMPLATE_ROOT}/src/services/teamService.js`
- `${COMP_TEMPLATE_ROOT}/src/services/answerService.js`
- `${COMP_TEMPLATE_ROOT}/src/services/questionsService.js`
- `${COMP_TEMPLATE_ROOT}/src/services/aiBrokerClient.js`
- `${COMP_TEMPLATE_ROOT}/src/services/aiBrokerService.js`
- `${COMP_TEMPLATE_ROOT}/src/hooks/useNoonAuth.js`
- `${COMP_TEMPLATE_ROOT}/src/hooks/useQuestions.js`
- `${COMP_TEMPLATE_ROOT}/src/config/envConfig.js`
- `${COMP_TEMPLATE_ROOT}/src/data/questionBank.js`

## Required App Wiring

The minimum shell wiring is:
1. `useNoonAuth()` for auth, session details, team, headers, and user role
2. `useQuestions()` for question loading
3. `initTelemetry(...)` and `trackActivityStart(...)`
4. `answerService.submitAnswer(...)` for MCQ answer submission
5. `multiplayerService.connect(...)` if the activity is shared
6. `cleanup()` on unmount

The reference shell wiring lives in:
- `${COMP_TEMPLATE_ROOT}/src/App.jsx`

## Auth Contract

Reference:
- `${COMP_TEMPLATE_ROOT}/src/hooks/useNoonAuth.js`

Important returned fields:
- `token`
- `user`
- `sessionDetails`
- `team`
- `status`
- `defaultHeaders`
- `error`

Important subfields:
- `user.userType`: `STUDENT`, `TEACHER`, `PRESENTER`, `ADMIN`
- `sessionDetails.sessionId`
- `sessionDetails.courseId`
- `sessionDetails.roomId`
- `sessionDetails.sessionSlideId`
- `sessionDetails.server`

## Question Loading Modes

### 1. Embedded Slide Activity

References:
- `${COMP_TEMPLATE_ROOT}/src/hooks/useQuestions.js`
- `${COMP_TEMPLATE_ROOT}/src/services/questionsService.js`

Backend path:
- `GET /noon2-core/courses/{courseId}/sessions/{courseSessionId}/slides/{sessionSlideId}/activity`

Mapped question shape:
- `{ id, prompt, choices, url, mcqId }`

This is the preferred mode when starting from the competition template.

### 2. PubNoon or Nolt Runtime Activity

References:
- `${PUBNOON_ROOT}/src/services/questionsService.js`
- `${PUBNOON_ROOT}/src/hooks/useQuestions.js`

Backend path:
- `GET /noon2-core/course-sessions/{courseSessionId}/nolt-activities/{noltId}/runtime-questions`

Use this mode when the activity is keyed by `noltId` instead of `sessionSlideId`.

### 3. Teacher-Side Question Assignment for Nolt

Reference:
- `${NOON2_FRONTEND_ROOT}/packages/teacher/src/requests/noltActivityQuestions/Api.ts`

Endpoints:
- `PUT /courses/{courseId}/sessions/{courseSessionId}/nolt-activity/questions`
- `GET /courses/{courseId}/sessions/{courseSessionId}/nolt-activity/questions`
- `DELETE /courses/{courseId}/sessions/{courseSessionId}/nolt-activity/questions`

Use this only when the task includes authoring or assigning the Nolt question bank from the teacher side.

## MCQ Answer Submission

Reference:
- `${COMP_TEMPLATE_ROOT}/src/services/answerService.js`

Answer submit path:
- `POST /noon2-core/v2/mcqs/{mcqId}/selectChoice/{choiceId}?source=LIVE`

Expectation:
- fire-and-forget on student submit
- do not block the local UI on the network response

## Telemetry

Reference:
- `${COMP_TEMPLATE_ROOT}/src/services/telemetry.js`

Core calls:
- `setConfig({ activityId, debug })`
- `initTelemetry({ accessToken, sessionDetails, user, defaultHeaders })`
- `trackActivityStart(details)`
- `trackActivityEnd(summary)`
- `trackPointStart(pointId, details)`
- `trackPointEnd(pointId, results)`
- `cleanup()`

## Multiplayer

References:
- `${COMP_TEMPLATE_ROOT}/src/services/MultiplayerService.js`
- `${PUBNOON_ROOT}/src/services/MultiplayerService.js`

Core calls:
- `connect({ accessToken, sessionDetails }, activityId)`
- `broadcast(payload)`
- `onMessage(callback)`
- `onStatusChange(callback)`
- `onHistoryReceived(callback)`
- `disconnect()`

For multiplayer game logic, borrow patterns from PubNoon. For platform connection behavior, trust the template service.

## Nolt Preview Rules

From `${NOLT_DIY_ROOT}/app/utils/selectStarterTemplate.ts`:
- prefer empty or relative API base URLs for local preview
- call relative paths like `fetch('/noon2-core/activity-events')`
- avoid hardcoded full backend URLs in preview mode
- implement role-based views when relevant

These rules are specifically there to keep WebContainer and preview mode working.
