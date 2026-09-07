# Noon2 Question Style

Use this file when the task is about matching the visual and interaction style of Noon2 questions.

## Primary References

- `${NOON2_FRONTEND_ROOT}/packages/student/src/containers/classroom/activity/StudentMultipleChoiceQuestionView.tsx`
- `${NOON2_FRONTEND_ROOT}/packages/student/src/containers/classroom/activity/ActiveQuestion.tsx`
- `${NOON2_FRONTEND_ROOT}/packages/student/src/containers/classroom/activity/MCQPreview.tsx`
- `${NOON2_FRONTEND_ROOT}/packages/common/src/classroom/poll/QuestionContainer.tsx`
- `${NOON2_FRONTEND_ROOT}/packages/common/src/studentSlide/StudentQuestion.tsx`
- `${NOON2_FRONTEND_ROOT}/packages/common/src/classroom/poll/ScrollingChoiceList.tsx`
- `${NOON2_FRONTEND_ROOT}/packages/common/src/classroom/poll/PollChoice.tsx`
- `${NOON2_FRONTEND_ROOT}/packages/student/src/containers/classroom/question/Utils.ts`

## Layout Model

The Noon2 question surface is not just a card.

It is a structured composition:
- `QuestionContainer` frames the question surface in a fixed slide-sized layout
- `StudentQuestion` renders the question stem and question-level actions
- `ScrollingChoiceList` renders vertically stacked choices with optional footer overlay

Important layout cues from `QuestionContainer.tsx`:
- fixed classroom slide dimensions
- question stem and choices are distinct zones
- header content sits above the main body
- choices area is vertically scrollable, not infinitely expanding

## Choice Behavior

`getChoiceProps(...)` in `Utils.ts` maps each choice into one of four states:
- `selected`
- `unselected`
- `correct`
- `incorrect`

That state model matters more than any specific color token.

When recreating the UI in a plain web activity:
- preserve the same state transitions
- preserve explicit submit vs live-selection behavior
- preserve correct-answer reveal behavior

## Choice Presentation

`PollChoice.tsx` shows the main interaction pattern:
- localized choice letters
- support for text and image choices
- clear selected, correct, and incorrect visual treatment
- optional avatars, vote counts, explanation or reflection affordances

For a web activity outside the Noon2 monorepo, recreate the same interaction structure in DOM and CSS instead of trying to import the React Native components directly.

## Question Flow

`ActiveQuestion.tsx` is the best reference for student answering behavior:
- choice selection can be local-only or free-flowing
- explicit submit button appears when needed
- free-flow activities can auto-submit and then expose navigation controls
- footer content is separate from the scrolling choices

If the new activity has MCQ steps, prefer this interaction pattern over PubNoon's custom `QuestionCard.jsx`.

## Review and Ended States

`StudentMultipleChoiceQuestionView.tsx` switches between:
- active state
- review state
- ended state

That split is useful even in standalone web activities. Keep the active answering UI separate from review or reveal UI instead of cramming all states into one component.

## Localization

Choice labels come from Noon2 translations:
- `A/B/C/D` in English
- `A/B/C/D` alternatives in other locales such as Arabic

If the activity is Arabic-first, keep the translated labels and RTL alignment consistent with Noon2 behavior.

## Practical Rule

When the task says "same style as noon2-frontend", copy:
- layout structure
- state semantics
- choice affordances
- submit and review flow

Do not copy:
- PubNoon's theme tokens
- ad hoc game-card styling
- custom gradients or battle chrome unless the task explicitly calls for that look
