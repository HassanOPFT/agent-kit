---
name: clean-code
disable-model-invocation: false
description: Guides stack-neutral clean-code naming, structure, boundaries, errors, testing, and design discipline inspired by Robert C. Martin. Use when source code is written, edited, generated, refactored, scaffolded, or reviewed in any language; during implementation, codegen, or patches; or when the user mentions clean code, Uncle Bob, SOLID (five object-oriented design principles), GRASP - General Responsibility Assignment Software Patterns, separation of concerns, cohesion, DRY - Don't Repeat Yourself, KISS, YAGNI, performance, complexity, DSA - data structures and algorithms, BUD, testing, or function design. Prefer language-specific project skills when they apply.
---

# Clean Code (Language-Agnostic)

**When to apply (routing):** the **`description` above is the primary signal** for when the model should attach this skill. Once loaded: whenever the agent is **writing, editing, or generating** code—follow this skill by default unless the user explicitly opts out.

**What it covers:** **SOLID** - five object-oriented design principles; **GRASP** - General Responsibility Assignment Software Patterns; **DRY** - Don't Repeat Yourself; **KISS** - Keep It Simple, Stupid; **YAGNI** - You Aren't Gonna Need It; **DSA** - data structures and algorithms; **BUD** - Bottlenecks, Unnecessary work, Duplicated work; pragmatic testing.

Use this skill for **any** codebase or generated snippet: prioritize **correctness**, **clarity**, and **safe change**. Prefer project- or language-specific skills when they exist (for example Google Java style or a TypeScript clean-code skill); this file stays **stack-neutral**. Apply idioms native to the language in use (see Type-System Guardrails).

## Workflow

1. **Intent**
   - Understand the feature/bug or review goal before style-only edits.
   - Preserve behavior unless the user asks for refactor-heavy changes.
   - Avoid cosmetic churn in untouched code.

2. **High-impact cleanup**
   - Improve naming clarity.
   - Reduce unit complexity (functions, methods, classes).
   - Isolate side effects and error handling.
   - Remove duplication when it encodes real rules and clearly improves readability.

3. **Robustness**
   - Check absence-of-value boundaries (null / nil / None / undefined — whatever the language uses).
   - Validate external inputs (API - application programming interface / UI - user interface / storage / network).
   - Keep failures explicit and actionable; separate error handling from core flow where practical.

4. **Report**
   - Actionable items only; focus on correctness, readability, and maintenance cost.
   - Prefer small local fixes over broad refactors unless the user asks for wider cleanup.
   - If two rules conflict, prefer file-level consistency and readability.

## Core Rules

- Names should reveal **intent** and domain meaning (`customerBalance`), not implementation noise (`data`, `temp`, `value`, `x`).
- Prefer **small units** (functions, methods, classes) with one clear responsibility; split when multiple conceptual steps are mixed. If a unit needs inline comments to explain steps, prefer smaller helpers.
- Prefer **simple signatures**; avoid long parameter lists and boolean flag clusters—use a small parameter object or options type when the language supports it.
- Prefer **early returns / guard clauses** to reduce nesting and improve scanability.
- Group related steps; separate **validation**, **transformation**, **side effects** (I/O, persistence, messaging), and **orchestration**.
- Replace **magic numbers and strings** with named constants or enums.
- Avoid duplicated logic; extract shared behavior when duplication appears more than once and intent stays clear.
- **Comments** explain non-obvious **why**; avoid narrating obvious **what**. Treat comments as a last resort.
- **Errors** should be explicit: fail fast on invalid state; prefer structured failure outcomes the language supports (result types, checked exceptions, error unions, `Optional` / `Result` / `Either`, or documented exception contracts) over silent failure or opaque error codes when practical.
- Prefer **immutability** or **narrow mutation** where the language and codebase allow it (`const` / `final` / `val` / frozen data / builders / copy-on-write); limit mutation scope.
- Use the **type system** (or contracts, schemas, assertions, runtime validation) to make **illegal states unrepresentable** when feasible—without over-engineering.
- Avoid untyped escape hatches (unchecked casts, stringly-typed data, catch-all object types) in favor of precise types, generics, or narrowed/validated values.
- Keep **modules cohesive**; one file or package should have one obvious purpose.
- Keep one statement per line.
- Use a single blank line to separate logical phases inside longer units (functions, methods, handlers—whatever the language uses).
- Use whitespace intentionally for scanability: group related lines, and add blank lines between distinct steps (validation, transformation, persistence), but avoid excessive vertical spacing.

## Type-System Guardrails (apply the idiom native to the language in use)

- Enable and respect the strictest reasonable compiler / linter / type-checker settings available for the language.
- Prefer the language's native composition and contract mechanisms for object modeling (structs/records for data; interfaces/protocols/traits for contracts meant to be extended).
- Model state machines and request/result variants with the language's closed-variant construct where one exists (discriminated unions, sealed types, algebraic data types / enums-with-payloads, `Result` / `Either`); fall back to a clearly documented tagged structure otherwise.
- Avoid deep optional / nil chaining when it hides missing-data bugs; validate once and pass safe values down.
- Do not over-abstract early; introduce abstractions only after clear duplication or volatility appears.

## Design Principles (High Level)

These sit at the same altitude: **where logic lives**, **how modules depend on each other**, and **what should change together**—not patterns for their own sake.

### SOLID - Single responsibility, Open/closed, Liskov substitution, Interface segregation, Dependency inversion

- **S**ingle responsibility: one reason to change per module or unit; split orchestration from pure transforms.
- **O**pen/closed: extend with additive changes (new cases, collaborators, implementations) instead of rewriting unrelated branches—especially for closed sets, keep variant handling in one place.
- **L**iskov substitution: subtypes honor the contract callers rely on.
- **I**nterface segregation: small, focused surfaces; callers do not depend on unused APIs - application programming interfaces.
- **D**ependency inversion: depend on abstractions or stable boundaries (ports) where volatility or testing demands it—not everywhere by default.

### GRASP - General Responsibility Assignment Software Patterns (responsibility assignment)

Assign behavior to the unit that already has the information (**Information expert**); keep **low coupling** and **high cohesion**; use a thin **Controller** or adapter at system edges for orchestration; use **Polymorphism** when behavior varies by type—without turning every branch into a deep hierarchy.

### Separation of Concerns and Cohesion

- **Separation of concerns**: validation, mapping to outward-facing shapes (for example DTOs - data transfer objects), I/O, UI orchestration, and domain logic are distinct—avoid one giant procedure unless the domain is trivial.
- **Cohesion / coupling**: strong cohesion inside a feature; loose coupling between features; clear module boundaries over clever cross-wiring.

### DRY - Don't Repeat Yourself; KISS - Keep It Simple, Stupid; YAGNI - You Aren't Gonna Need It

- **DRY - Don't Repeat Yourself**: remove duplicated **knowledge** (rules that must stay in sync), not merely repeated syntax.
- **KISS - Keep It Simple, Stupid**: prefer the straightforward design the team can read and change.
- **YAGNI - You Aren't Gonna Need It**: do not add layers or flexibility for hypothetical futures.

### Composition

- Prefer **composition over inheritance**: combine small collaborators (functions, classes, modules) instead of deep subclass trees unless inheritance truly fits the domain.

### How to Apply (Pragmatic)

- Use these ideas when they improve **clarity, testability, or safe change**—not as a line-by-line checklist.
- Keep **MVP - minimum viable product** bias: the smallest design that meets current requirements safely.

## Logging (compass)

Log **outcomes and decisions with stable reason codes and entity ids** (`schoolStudentId`,
`jobId`, `cohortId`) — not chatter, not secrets, not full PII payloads; use `info` for expected
business results, `warn` when a best-effort side effect failed but the request still succeeded,
`error` only for unexpected failures (once, with context); never log-and-rethrow the same failure
without adding signal, and keep wording correct under retries so a duplicate run does not look
like a new incident.

## Testing (Pragmatic)

Test behavior that can break; not every branch or wiring detail. Prefer a few high-signal cases over exhaustive coverage. Keep tests **fast, independent, repeatable, and self-validating**.

- Couple tests to **observable behavior / contracts**, not implementation structure (Beck: behavioral, structure-insensitive).
- Prefer the smallest set that would catch a real regression—happy path plus load-bearing edges only when they encode distinct risk.
- Skip brittle or redundant cases (pure wiring, duplicate variants).
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

- **Structure choice (DSA - data structures and algorithms):** match the operation to the structure—e.g. a hash set/map for membership or keyed lookup instead of repeated linear scans over a list; build an index once when you need many lookups; avoid accidental **O(n²)** from nested loops or a linear find inside a loop when **O(n)** or **O(n log n)** is enough with a better structure or sort.
- **Bottlenecks (B in BUD):** hot paths (request handlers, tight loops, code over large collections) dominate cost—optimize there first; keep cold paths simple.
- **Unnecessary work (U in BUD):** drop dead branches, redundant passes over the same data, and transforms that can run once upstream or be skipped when inputs are unchanged.
- **Duplicated work (D in BUD):** do not recompute the same derived value on every iteration/call; memoize, cache, or precompute only when measurement or clear logical duplication shows it matters—avoid caching everything by default.

## Review Output Format

When reporting issues or fixes, use:

- `Issue:` concrete problem
- `Why:` impact on correctness, maintenance, or performance
- `Fix:` exact change or refactor direction

## Continuous learning

After applying this skill, **do not** propose skill edits by default. Only when usage surfaced a **repeatable, cross-cutting gap** that would have changed the outcome:

- A convention not covered here (shared primitives, framework patterns, project-wide naming/error conventions).
- A mistake that appeared twice in the session or would likely recur.
- A lint / type / review failure tied to a rule worth encoding once.

**When to act:** append **at most 1–2 short bullets** under `## Learned patterns` below—one line each, actionable, no restating existing sections, prefixed with the repo/language it applies to (e.g. `noon2-frontend (TS/RN):`, `noon2_core (Java):`, `noon-citadel (TS):`). Skip one-off fixes, generic Uncle Bob advice, and anything already in `AGENTS.md` / `CLAUDE.md` / `DESIGN.md`.

**How to act:** ask the user before editing this file unless they asked to maintain the skill. If they agree, add bullets only; do not rewrite the skill body.

## Learned patterns

<!-- Append repo/language-tagged bullets here after confirmed skill updates. -->
