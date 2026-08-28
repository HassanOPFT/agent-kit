---
name: clean-code
description: Applies Clean Code, Pragmatic habits, SOLID, BUD optimization, sensible DSA choices, and performance discipline to generated or modified code. Use when implementing, refactoring, testing, reviewing, or solving algorithmic problems.
disable-model-invocation: false
---

# Clean Code & Pragmatic Craft

Follow for **every** line you generate, add, or change. Prefer project conventions; otherwise use this skill.

For UI/UX decisions during planning and implementation, follow the `ui-ux` skill.

---

## Naming (Clean Code)

Intent over implementation detail. Pronounceable, searchable names; no encodings or vague `tmp`-style labels.

Nouns for data/types; verb phrases for actions; `is`/`has` predicates for booleans. Replace opaque literals with named constants.

---

## Functions and methods

Small; one abstraction level; one job (names needing “and” are a smell). Few parameters (0–2); no behavior-switching flags—split or use polymorphism.

**Command–query:** commands mutate and return nothing meaningful; queries do not mutate. Prefer exceptions for flow; handle at boundaries; never swallow errors.

---

## Comments

Code shows what/how; comments show **why**, constraints, or non-obvious tradeoffs. Remove dead/commented-out code; TODOs only if actionable.

---

## Classes and modules

One reason to change. Narrow public API; hide internals; depend on abstractions at varying boundaries. High cohesion; no grab-bag modules.

---

## SOLID

**S — Single Responsibility:** one job per unit.

**O — Open/Closed:** extend via types/composition; do not churn stable cores per variant.

**L — Liskov Substitution:** subtypes honor contracts.

**I — Interface Segregation:** small interfaces—no unused methods on clients.

**D — Dependency Inversion:** policy and details both depend on abstractions (ports/interfaces).

---

## Pragmatic habits

**DRY** ideas, not every duplicate line—abstract when the rule is clear. **Orthogonality:** localized change.

**Tracer bullets** over big speculative layers. **Broken windows:** leave touched files slightly better (in scope). **No guessing:** clarify vague requirements.

---

## BUD

Run **BUD** before micro-optimizing.

**Bottlenecks:** what dominates time/memory—fix that first.

**Unnecessary work:** short-circuit, prune, skip unused results; avoid redundant full scans when indexes or incremental state help.

**Duplicated work:** memoize/cache; maps/sets over repeated linear lookups; build aux structures once.

---

## Data structures and algorithms

Match structure to access (lookup, order, ranges, duplicates, memory). Simplest option that meets complexity; note non-obvious picks.

State time/space when non-trivial; validate against realistic limits. Patterns: two pointers, sliding window, prefix sums, BFS/DFS + visited, balanced divide-and-conquer.

Watch hidden costs: resorting every query, big copies, nested scans, hot-path string churn.

---

## Performance

Measure or reason about hotspots; no micro-opts on cold paths. Prefer asymptotic and query-shape wins over tricks until profiling says otherwise.

Cut N+1, unbounded fan-out/memory, blocking I/O on hot paths, busy-wait. Stream/chunk large data; backpressure; timeouts/cancel where supported.

Interview-style: walk concrete cases (empty, single, large); fix root cause, not special-case piles.

---

## Data and side effects

Immutability when practical. Isolate I/O, time, randomness, globals for tests. Validate at boundaries; keep domain logic transport-free.

---

## Tests

Fast, isolated, repeatable. One concept per test; name encodes scenario + expectation. Arrange–act–assert, structure visible at a glance.

---

## Review gate

Honest names and function sizes? Dead noise gone? Errors/deps at the right layer? File still quick to scan?

BUD clean on hot paths? Complexity and structures sane for scale?

If not, refactor in scope before done.
