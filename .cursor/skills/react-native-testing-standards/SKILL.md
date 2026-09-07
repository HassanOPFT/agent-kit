---
name: react-native-testing-standards
description: Use when writing or reviewing tests, planning coverage, debugging flaky tests, or choosing unit vs component vs E2E tests in this monorepo. Applies layered testing strategy (pyramid), Jest and React Native Testing Library practices, and React Native–specific pitfalls.
---

# React Native testing standards

## Mental model: testing pyramid

Industry-standard shape (tune per team; ratios are guidance, not law):

| Layer                       | Typical share | Purpose                                                                                    |
| --------------------------- | ------------- | ------------------------------------------------------------------------------------------ |
| **Unit**                    | Largest       | Pure functions, reducers, hooks (logic), utilities — fast, no device                       |
| **Component / integration** | Middle        | Screens and components with Jest + **React Native Testing Library** (user-centric queries) |
| **E2E**                     | Smallest      | Critical paths on real simulators/devices (checkout, auth, session flows)                  |

**Principle:** many cheap tests at the bottom; few expensive E2E tests at the top. Do not duplicate the same assertion at every layer.

## Stack alignment (conventional RN)

- **Runner:** Jest (default in RN ecosystem).
- **Component tests:** `@testing-library/react-native` — query like a user (text, role, label), not internal state.
- **HTTP:** Prefer **MSW** (or project patterns) for network in tests; avoid arbitrary `setTimeout` for async UI — use **`findBy*`** / **`waitFor`** from Testing Library.
- **E2E:** **Detox** (gray-box sync, JS-heavy teams) or **Maestro** (YAML, cross-platform, low ceremony) — pick one per product line; document in repo. **testID** / accessibility labels for stable selectors.

## React Native Testing Library (RNTL) — do / don’t

**Do**

- Prefer **`getByRole`**, **`getByText`**, **`getByLabelText`**, **`getByPlaceholderText`** (per [Testing Library guidance](https://testing-library.com/docs/queries/about#priority)).
- Use **`userEvent`** or **`fireEvent`** for interactions; assert **observable** outcomes (text, navigation mock, callback).
- Async UI: **`findBy*`** or **`waitFor`** until the condition holds; avoid fixed sleeps.
- Test **accessibility**: `accessible`, `accessibilityLabel` where it affects real users.

**Don’t**

- Assert on **props/state** of child components or **snapshot entire screens** unless the snapshot is small and stable.
- Couple tests to **component names** or **hook order** (implementation details).
- **Over-mock** — mock boundaries (API, native modules), not every child component unless necessary for isolation.

## Jest — RN-specific

- **Native modules:** Use manual mocks under `__mocks__` or `jest.mock` for `AsyncStorage`, `NetInfo`, `react-native-reanimated`, etc. Prefer **official** mocks from libraries when available.
- **Timers:** Use Jest fake timers only when testing time-dependent logic; reset in `afterEach`.
- **Navigation:** Wrap with **`NavigationContainer`** or mock `useNavigation` / navigation ref per project patterns.
- **Monorepo:** Tests live in **`__tests__/`** or `*.test.ts(x)` per package; run via each package’s **`jest.config.js`** (this repo: `packages/common`, `student`, `teacher`, `facilitator`, `admin`, `genai`).

## What to test first

- Pure utilities and data transforms.
- Reducers, selectors, and non-trivial **custom hooks**.
- Bug fixes: add a **regression test** that fails without the fix.
- Critical user paths at E2E scope only when unit/component tests cannot provide enough confidence.

## What to skip or keep thin

- Third-party UI one-to-one behavior (trust the library; test your integration).
- Layout-only snapshots of large trees (high churn, low signal).
- Duplicating the same scenario in **both** a heavy E2E and a full-screen component test — choose one primary layer.

## CI and flakiness

- Prefer **`--maxWorkers`** tuned for CI (avoid CPU thrash); enable **`--detectOpenHandles`** locally when debugging leaks.
- E2E: isolate test data, stable build types (often release-like), retries only as a last resort with root-cause tracking.

## Quick checklist (new test)

- [ ] Right layer (unit vs RNTL vs E2E)?
- [ ] Queries reflect **user-visible** behavior?
- [ ] Async handled with **`findBy` / `waitFor`**, not `sleep`?
- [ ] Mocks at **system boundaries**, not every leaf component?
- [ ] Test fails when the bug returns?

## Further reading (external)

- [Testing Library — Guiding Principles](https://testing-library.com/docs/guiding-principles)
- [React Native Testing Library](https://callstack.github.io/react-native-testing-library/)
- [Jest — Docs](https://jestjs.io/docs/getting-started)

When repo-specific conventions conflict (e.g. custom test helpers), follow **this monorepo’s existing `jest-setup.ts` and adjacent tests** as the source of truth.
