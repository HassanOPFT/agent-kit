---
name: google-java-style
description: Apply concise Google Java Style rules to Java code changes. Use when editing Java files, fixing formatting, reviewing style violations, or when the user mentions Google Java style/imports/naming/Javadoc consistency.
---

# Google Java Style (Concise)

Use this skill to apply practical, high-signal Google Java Style rules with clean-code defaults.

## Workflow

1. Apply formatter-friendly fixes first (indentation, wrapping, braces, spacing).
2. Check structural rules (imports, class/file organization, naming).
3. Check behavior-adjacent style rules (`@Override`, switch fall-through comments, ignored exceptions).
4. Report only actionable issues with exact file paths and clear fixes.

## Core Rules

- Use UTF-8, spaces (no tabs), and keep code lines <= 100 chars (except allowed cases like imports/package/text blocks/long URLs).
- Use braces for `if/else/for/do/while`, including single-line bodies.
- Keep one statement per line.
- Use a single blank line to separate logical phases inside longer methods.
- Use whitespace intentionally for scanability where helpful: group related lines, and add
  blank lines between distinct steps (validation, transformation, persistence), but avoid
  excessive vertical spacing.
- Avoid wildcard imports (e.g., `import java.util.*;`).
- Import order: static imports block, blank line, non-static imports block; ASCII sort within each block.
- Exactly one top-level class per `.java` file; file name matches class name.
- Keep overloaded methods/constructors contiguous.
- Prefer lowerCamelCase for methods/fields/params/locals; UpperCamelCase for classes; UPPER_SNAKE_CASE only for true constants.
- Use `@Override` whenever legal (except permitted deprecated-parent case).
- Don’t silently ignore caught exceptions; if intentionally ignored, explain why in a comment.
- In old-style `switch`, mark intentional fall-through with a comment; ensure switches are exhaustive.
- Use uppercase `L` for long literals (e.g., `3000000000L`).

## Javadoc Minimum

- Add Javadoc for visible public/protected APIs unless truly self-explanatory.
- Start with a summary fragment.
- When block tags exist, keep order: `@param`, `@return`, `@throws`, `@deprecated`.

## Clean Code Overlays (Pragmatic)

- Use meaningful names that reveal intent, not implementation details.
- Avoid vague names like `data`, `temp`, `x`; prefer explicit domain names like `customerBalance`.
- Keep functions small and focused on one responsibility.
- If a method needs inline comments to explain steps, prefer splitting into smaller helpers.
- Treat comments as a last resort; comment `why` decisions, not obvious `what`.
- Keep formatting consistent and readable: indentation, spacing, and logical block separation.
- Prefer exceptions over error codes and keep error handling separate from core business flow.
- Avoid duplication; extract repeated logic and follow DRY when it improves clarity.
- Keep code testable and preserve critical unit-test qualities: fast, independent, repeatable, self-validating.
- Always optimize for bottlenecks, unnecessary work, and duplicate work.

## Testing (Pragmatic)

Test behavior that can break; not every branch or wiring detail. Prefer a few high-signal cases over exhaustive coverage.

- Couple tests to **observable behavior / contracts**, not implementation structure (Beck: behavioral, structure-insensitive).
- Prefer the smallest set that would catch a real regression—happy path plus load-bearing edges only when they encode distinct risk.
- Skip brittle or redundant cases (duplicate variants, pure wiring).
- A test is a bet: keep it only if it is worth writing and maintaining relative to the code it protects.
- Honor repo-required coverage for new public surfaces; still keep new cases lean.
- Name tests after the behavior they protect ("rejects expired token"), not the method under test.
- Keep tests deterministic: inject clocks, seed randomness, no real network/time — a flaky test costs more than no test.
- Keep tests independent: no shared mutable state, no order dependence; each test builds its own minimal setup.
- In fixtures, specify only the data the case cares about; default the rest (builders/factories) so tests state intent, not noise.
- Structure each test as arrange/act/assert with one logical assertion — if you need "and", it's probably two tests.
- A new test must fail before the fix — proves it can actually catch the regression.

## Pragmatic Enforcement

- Prioritize issues that affect readability, correctness, or maintenance cost.
- Do not request cosmetic churn in untouched code.
- Prefer small local fixes over broad refactors unless the user asks for wider cleanup.
- If two rules conflict, prefer file-level consistency and readability.

## TODO Format

Use (intentional deviation from official Google Java Style `TODO(username)` format):

`// TODO: <link-or-ticket> - <short reason>`

Prefer an issue/bug URL or ticket ID over person/team mentions.

## Response Format

When reporting style fixes/review findings, use:

- `Issue:` what violates style
- `Why:` why it matters
- `Fix:` exact change to apply

## Continuous learning

After applying this skill, **do not** propose skill edits by default. Only when usage surfaced a **repeatable, repo-specific gap** that would have changed the outcome:

- A noon2_core convention not covered here (entity/DTO masking, `@Transactional` scope, Flyway/NoonId patterns, test style).
- A mistake that appeared twice in the session or would likely recur (mutating managed entities, returning `@Entity` from controllers).
- A checkstyle/CI or review feedback tied to a rule worth encoding once.

**When to act:** append **at most 1–2 short bullets** under `## Learned patterns (noon2_core)` below—one line each, actionable, no restating existing sections. Skip one-off fixes, generic Google Style advice, and anything already in `AGENTS.md`.

**How to act:** ask the user before editing this file unless they asked to maintain the skill. If they agree, add bullets only; do not rewrite the skill body.

## Learned patterns (noon2_core)

<!-- Append repo-specific bullets here after confirmed skill updates. -->
