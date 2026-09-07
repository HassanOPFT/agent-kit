# PubNoon Patterns

Use this file when the task is about gameplay structure, multiplayer flow, or role-specific screens.

## Primary References

- `${PUBNOON_ROOT}/README.md`
- `${PUBNOON_ROOT}/src/App.jsx`
- `${PUBNOON_ROOT}/src/game/gameState.js`
- `${PUBNOON_ROOT}/src/game/gameActions.js`
- `${PUBNOON_ROOT}/src/game/messageHandler.js`
- `${PUBNOON_ROOT}/src/views/PresenterView.jsx`
- `${PUBNOON_ROOT}/src/views/CaptainController.jsx`
- `${PUBNOON_ROOT}/src/views/MemberView.jsx`
- `${PUBNOON_ROOT}/src/components/QuestionCard.jsx`

## Architecture Summary

PubNoon's `App.jsx` is the orchestrator. It owns:
- auth and team resolution
- question loading
- reducer state
- user role derivation
- multiplayer listeners
- timer and phase transitions
- per-view routing

That shape is worth reusing even when the specific mechanics change.

## Role Split

PubNoon uses three effective surfaces:
- `presenter`: shared classroom screen
- `captain`: student with extra control surface
- `member`: student answering questions without action controls

Important detail:
- captain is not purely an auth role
- it is derived from game state and team ownership

Use this pattern when the activity has asymmetric team responsibilities.

## State and Message Flow

Game state is reducer-driven and multiplayer messages are normalized through `messageHandler.js`.

Key ideas to reuse:
- explicit message types
- a single reducer as the source of truth
- host-driven state broadcasts
- late-joiner history handling
- derived round and phase state instead of implicit UI timers

## Host Election

PubNoon elects a host from the registered teams and lets that host drive:
- auto-start
- phase changes
- authoritative state broadcasts

Reuse this when the activity needs deterministic shared progression and no dedicated server-side game loop.

## Question Loop

PubNoon slices the full question list into per-round chunks and uses question performance to feed gameplay resources.

Patterns worth reusing:
- derive current round question slice from reducer state
- keep question answering separate from post-question action phases
- broadcast summary scores instead of every minor local state update when that is enough

## What To Borrow vs What To Ignore

Borrow:
- app orchestration
- reducer and message architecture
- role separation
- host election
- round-based question loop

Do not automatically borrow:
- the dark battle theme
- the custom `QuestionCard.jsx` look
- battle-specific AP, attack, shield, or heal rules unless the task wants them

`QuestionCard.jsx` is useful as a minimal standalone web reference, but the final question UX should usually follow Noon2 frontend patterns instead.
