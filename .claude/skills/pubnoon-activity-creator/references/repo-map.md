# Repo Map

Use this file to jump straight to the most relevant local sources.

All paths below are expressed in terms of the repo roots returned by:

```bash
bash scripts/discover_noon_repos.sh "$PWD"
```

## PubNoon

- `${PUBNOON_ROOT}/README.md`
  - overview of roles, loop, and architecture
- `${PUBNOON_ROOT}/src/App.jsx`
  - orchestration pattern for auth, reducer, multiplayer, and role routing
- `${PUBNOON_ROOT}/src/game/gameState.js`
  - reducer state shape and phase transitions
- `${PUBNOON_ROOT}/src/game/messageHandler.js`
  - shared message types and normalization
- `${PUBNOON_ROOT}/src/views/PresenterView.jsx`
  - presenter-screen gameplay surface
- `${PUBNOON_ROOT}/src/views/CaptainController.jsx`
  - captain-only controls plus question flow
- `${PUBNOON_ROOT}/src/views/MemberView.jsx`
  - member question flow
- `${PUBNOON_ROOT}/src/components/QuestionCard.jsx`
  - minimal standalone web question card
- `${PUBNOON_ROOT}/src/styles/theme.js`
  - PubNoon-specific theme tokens

## Competition Template

- `${COMP_TEMPLATE_ROOT}/.bolt/prompt`
  - template prompt and platform contract summary
- `${COMP_TEMPLATE_ROOT}/src/App.jsx`
  - reference shell wiring for auth, questions, telemetry, answers, and multiplayer
- `${COMP_TEMPLATE_ROOT}/src/hooks/useNoonAuth.js`
  - auth and session handshake contract
- `${COMP_TEMPLATE_ROOT}/src/hooks/useQuestions.js`
  - embedded activity question hook
- `${COMP_TEMPLATE_ROOT}/src/services/questionsService.js`
  - embedded slide activity endpoint and question mapping
- `${COMP_TEMPLATE_ROOT}/src/services/answerService.js`
  - MCQ submit endpoint
- `${COMP_TEMPLATE_ROOT}/src/services/telemetry.js`
  - analytics lifecycle helpers
- `${COMP_TEMPLATE_ROOT}/src/services/MultiplayerService.js`
  - platform multiplayer client

## Nolt.diy

- `${NOLT_DIY_ROOT}/app/lib/common/prompts/noon-platform-instructions.ts`
  - the clearest statement of the locked-file and integration rules
- `${NOLT_DIY_ROOT}/app/utils/selectStarterTemplate.ts`
  - preview-specific constraints, especially relative `/noon2-core/*` usage
- `${NOLT_DIY_ROOT}/app/utils/constants.ts`
  - starter template registration for the competition template

## Noon2 Frontend

- `${NOON2_FRONTEND_ROOT}/packages/student/src/containers/classroom/activity/StudentMultipleChoiceQuestionView.tsx`
  - active, review, and ended MCQ routing
- `${NOON2_FRONTEND_ROOT}/packages/student/src/containers/classroom/activity/ActiveQuestion.tsx`
  - submit flow and free-flow navigation pattern
- `${NOON2_FRONTEND_ROOT}/packages/student/src/containers/classroom/activity/MCQPreview.tsx`
  - ended-state and class-vote rendering
- `${NOON2_FRONTEND_ROOT}/packages/common/src/classroom/poll/QuestionContainer.tsx`
  - question layout skeleton
- `${NOON2_FRONTEND_ROOT}/packages/common/src/studentSlide/StudentQuestion.tsx`
  - question stem wrapper and actions
- `${NOON2_FRONTEND_ROOT}/packages/common/src/classroom/poll/ScrollingChoiceList.tsx`
  - scrolling stacked choices with footer overlay
- `${NOON2_FRONTEND_ROOT}/packages/common/src/classroom/poll/PollChoice.tsx`
  - choice visuals and interaction affordances
- `${NOON2_FRONTEND_ROOT}/packages/student/src/containers/classroom/question/Utils.ts`
  - choice state mapping
- `${NOON2_FRONTEND_ROOT}/packages/teacher/src/requests/noltActivityQuestions/Api.ts`
  - teacher-side Nolt question assignment endpoints

## Noon2 Core

- `${NOON2_CORE_ROOT}`
  - consult only when the task requires backend-side behavior or the frontend contract is unclear
