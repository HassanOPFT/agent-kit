---
name: clean-typescript-style
disable-model-invocation: false
description: Apply TypeScript and TSX clean-code rules inspired by Robert C. Martin whenever TypeScript or TSX source is written, edited, generated, refactored, or reviewed. Use during implementation, codegen, patches, new components, hooks, or tests in this repo, plus code reviews and refactors. Also when the user mentions clean code, Uncle Bob, SOLID (five object-oriented design principles), GRASP - General Responsibility Assignment Software Patterns, separation of concerns, cohesion, DRY - Don't Repeat Yourself, performance, complexity, DSA - data structures and algorithms, or function design.
---

# TypeScript Clean Code (Uncle Bob Inspired)

**When to apply:** whenever the agent is **writing, editing, or generating** `.ts` / `.tsx` in this workspace—follow this skill by default unless the user explicitly opts out.

Use this skill to enforce practical clean-code standards in TypeScript without over-engineering.

When invoked, do the following:

1. Identify intent first
   - Understand the feature/bug intent before style changes.
   - Preserve behavior unless user explicitly asks for refactor-heavy changes.
   - Avoid cosmetic churn in untouched code.

2. Apply high-impact cleanup
   - Improve naming clarity.
   - Reduce function complexity.
   - Isolate side effects and error handling.
   - Remove duplication when it clearly improves readability.

3. Validate robustness
   - Check null/undefined boundaries.
   - Validate external inputs (API - application programming interface / UI - user interface / storage).
   - Keep failures explicit and actionable.

4. Report only actionable changes
   - Focus on correctness, readability, and maintenance cost.
   - Provide concrete edits, not vague preferences.

## Core Rules

- Use meaningful names that reveal business intent (`customerBalance`) over generic names (`data`, `temp`, `value`).
- Prefer small functions with one responsibility; split when a function does multiple conceptual steps.
- Keep function signatures simple; avoid too many boolean flags or long parameter lists.
- Prefer early returns to reduce nesting and improve scanability.
- Keep related logic together; separate validation, transformation, side effects, and orchestration.
- Replace magic numbers/strings with well-named constants.
- Avoid duplicated logic; extract shared behavior when duplication appears more than once and intent stays clear.
- Keep comments rare; comment non-obvious reasoning (`why`), not obvious mechanics (`what`).
- Keep error handling explicit; fail fast on invalid state and return clear typed outcomes when possible.
- Prefer immutable patterns by default (`const`, pure helpers) and limit mutation scope.
- Use TypeScript types to make illegal states hard to represent (unions, discriminated unions, narrow interfaces).
- Avoid `any`; prefer precise types, `unknown` with narrowing, or generics when needed.
- Keep modules cohesive; one file should represent one clear domain purpose.
- Keep one statement per line.
- Use a single blank line to separate logical phases inside longer methods.
- Use whitespace intentionally for scanability where helpful: group related lines, and add
  blank lines between distinct steps (validation, transformation, persistence), but avoid
  excessive vertical spacing.

## TypeScript-Specific Guardrails

- Enable strict-friendly code style in changes (`strictNullChecks` assumptions).
- Prefer `type` for composition-heavy modeling and `interface` for object contracts meant for extension.
- Use discriminated unions for state machines and request/result variants.
- Avoid deep optional chaining when it hides missing-data bugs; validate once and pass safe values down.
- Do not over-abstract early; introduce abstractions only after clear duplication or volatility appears.

## Design Principles (High Level)

These sit at the same altitude: **where logic lives**, **how modules depend on each other**, and **what should change together**—not specific patterns unless they clearly serve the goal.

### SOLID - Single responsibility, Open/closed, Liskov substitution, Interface segregation, Dependency inversion

- **S**ingle responsibility: one reason to change per module/function; split orchestration from pure transforms.
- **O**pen/closed: extend behavior with additive changes (new cases, new collaborators) instead of rewriting unrelated branches—especially for closed sets (enums) keep variant handling in one place.
- **L**iskov substitution: subtypes honor the contract callers rely on (subclassing and shared interfaces).
- **I**nterface segregation: small, focused types and APIs - application programming interfaces; callers do not depend on unused surface area.
- **D**ependency inversion: depend on abstractions or stable boundaries (ports) where volatility or testing demands it—not everywhere by default.

### GRASP - General Responsibility Assignment Software Patterns (responsibility assignment)

Use when deciding **who should own** a behavior: favor the type that already has the information (**Information expert**), keep **low coupling** and **high cohesion**, use a **Controller** for orchestration at system edges, and **Polymorphism** when behavior varies by type—without turning every `if` into a class hierarchy.

### Separation of Concerns and Cohesion

- **Separation of concerns**: validation, mapping to DTOs (data transfer objects), I/O, and UI (user interface) orchestration are distinct concerns—do not merge them in one giant function without need.
- **Cohesion / coupling**: strong cohesion inside a file or feature; loose coupling between features. Prefer clear module boundaries over clever cross-imports.

### DRY - Don't Repeat Yourself; KISS - Keep It Simple, Stupid; YAGNI - You Aren't Gonna Need It

- **DRY - Don't Repeat Yourself**: remove duplicated _knowledge_ (rules that must stay in sync), not merely repeated syntax.
- **KISS - Keep It Simple, Stupid**: prefer the straightforward design that the team can read and change.
- **YAGNI - You Aren't Gonna Need It**: do not build flexibility or layers for hypothetical futures.

### Composition

- Prefer **composition over inheritance** when sharing behavior: combine small pieces (functions, hooks, components) instead of deep subclass trees unless the domain truly fits inheritance.

### How to Apply (Pragmatic)

- Reach for these principles when they improve **clarity, testability, or safe change**—not as a checklist on every line.
- Keep **MVP - minimum viable product** bias: the simplest design that meets current requirements safely.

## Testing (Pragmatic)

Test behavior that can break; not every branch or wiring detail. Prefer a few high-signal cases over exhaustive coverage.

- Couple tests to **observable behavior / contracts**, not implementation structure (Beck: behavioral, structure-insensitive).
- Prefer the smallest set that would catch a real regression—happy path plus load-bearing edges only when they encode distinct risk.
- Skip brittle or redundant cases (prop wiring, duplicate variants).
- A test is a bet: keep it only if it is worth writing and maintaining relative to the code it protects.
- Honor repo-required coverage for new public surfaces; still keep new cases lean.
- Name tests after the behavior they protect ("rejects expired token"), not the method under test.
- Keep tests deterministic: inject clocks, seed randomness, no real network/time — a flaky test costs more than no test.
- Keep tests independent: no shared mutable state, no order dependence; each test builds its own minimal setup.
- In fixtures, specify only the data the case cares about; default the rest (builders/factories) so tests state intent, not noise.
- Structure each test as arrange/act/assert with one logical assertion — if you need "and", it's probably two tests.
- A new test must fail before the fix — proves it can actually catch the regression.

## Efficiency, Complexity, and Waste (DSA - Data Structures and Algorithms; BUD - Bottlenecks, Unnecessary Work, Duplicated Work)

Think in **data structures and algorithms** so the code stays **performant** without premature micro-optimization.

- **Structure choice (DSA - data structures and algorithms):** match the operation to the structure—e.g. `Set`/`Map` for membership or keyed lookup instead of repeated linear scans over arrays; build an index once when you need many lookups; avoid accidental **O(n²)** from nested loops or `.find` inside a loop when **O(n)** or **O(n log n)** is enough with a better structure or sort.
- **Bottlenecks (B in BUD):** hot paths (render, tight loops, handlers on large lists) dominate cost—optimize there first; keep cold paths simple.
- **Unnecessary work (U in BUD):** drop dead branches, redundant passes over the same data, and transforms that can run once upstream or be skipped when inputs are unchanged.
- **Duplicated work (D in BUD):** do not recompute the same derived value on every iteration or render; memoize, cache, or precompute only when measurement or clear logical duplication shows it matters—avoid caching everything by default.

## Review Output Format

When reporting issues or fixes, use:

- `Issue:` concrete problem
- `Why:` maintenance/correctness/performance impact
- `Fix:` exact refactor or code change

## Continuous learning

After applying this skill, **do not** propose skill edits by default. Only when usage surfaced a **repeatable, repo-specific gap** that would have changed the outcome:

- A monorepo convention not covered here (`common/` primitives, `useThemedStyles`, RTL/`safeStyles`, Redux/classroom patterns).
- A mistake that appeared twice in the session or would likely recur (hardcoded colors, `fetch` in `useEffect`, missing `React.memo`).
- A lint/type failure tied to a rule worth encoding once.

**When to act:** append **at most 1–2 short bullets** under `## Learned patterns (noon2-frontend)` below—one line each, actionable, no restating existing sections. Skip one-off fixes, generic advice, and anything already in `AGENTS.md` or `DESIGN.md`.

**How to act:** ask the user before editing this file unless they asked to maintain the skill. If they agree, add bullets only; do not rewrite the skill body.

## Learned patterns (noon2-frontend)

<!-- Append repo-specific bullets here after confirmed skill updates. -->
