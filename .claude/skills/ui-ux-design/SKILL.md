---
name: ui-ux-design
description: Designs and implements usable, accessible interfaces across apps and platforms. Covers hierarchy, states, forms, navigation, localization, theming, and interaction quality. Use when building or revising screens, components, flows, dashboards, onboarding, empty/error states, accessibility, or visual polish, even if the user does not explicitly mention UX - user experience or design.
---

# UI/UX - user interface / user experience design (Generic)

## Abbreviations

- **UI** - user interface
- **UX** - user experience
- **WCAG** - Web Content Accessibility Guidelines
- **AA** - WCAG conformance level AA (accessibility criteria including contrast)
- **RTL** - right-to-left (writing direction / locale layout)
- **LTR** - left-to-right
- **CTA** - call to action

Apply this skill whenever generating or refactoring UI so work aligns with **task success**, **accessibility aligned with WCAG - Web Content Accessibility Guidelines**, and **existing product design patterns**.

## Design-system alignment (do this first)

- **Theme tokens**: Prefer design tokens (colors, spacing, typography, radii, shadows) over hardcoded values for product UI.
- **Semantic colors**: Use semantic buckets (`Content`, `Surface`, `Background`, `Border`, `Interactive`, `Feedback`) rather than raw color names when possible.
- **Spacing scale**: Follow a consistent spacing scale for rhythm; avoid arbitrary magic numbers unless extending the scale intentionally.
- **Typography scale**: Use a consistent type system (roles, sizes, weights) to preserve hierarchy and readability.
- **Directionality**: Support mirrored layouts and directional spacing for RTL - right-to-left / LTR - left-to-right locales.
- **Consistency**: Reuse existing shared components and established patterns before creating one-off styles.

## Core principles

- **Task success first**, decoration second; every screen should answer “what is the one job here?”
- **One primary action** per view; secondary actions visually and hierarchically subordinate.
- **Explicit system status**: loading, empty, error, success—never silent failure.
- **Accessibility by default** (WCAG - Web Content Accessibility Guidelines 2.2; **AA** - WCAG conformance level AA mindset): perceivable, operable, understandable; keyboard and screen reader where the platform supports it.
- **Recognition over recall**: visible labels, sensible defaults, clear next step.
- **Recoverable errors**: validation near the field; destructive actions need confirmation and escape.

## Flexible workflow

Adapt order to tickets; do not skip alignment or verification.

```md
UI/UX Progress

- [ ] Align with existing design system, tokens, directionality, and shared components
- [ ] Clarify goal, user, primary task, success criteria
- [ ] Define states and interaction contract (including async)
- [ ] Structure layout, hierarchy, progressive disclosure
- [ ] Accessibility: semantics, focus, contrast, motion, touch targets
- [ ] Forms: validation, errors, recovery
- [ ] Verify flows, breakpoints, and edge states
```

## 1) Goal, user, primary task

- Name the **single highest-priority outcome** for the screen or flow.
- Success in one sentence (“User can X with minimal steps / without data loss”).
- If requirements are thin, **state assumptions** and proceed.

## 2) States and interaction contract

Cover what applies:

| Area | States to consider |
|------|-------------------|
| Data | loading, empty, partial, stale, success, error |
| Forms | pristine, dirty, validating, submitting, field/global errors |
| Async actions | pending within ~100–300ms; avoid “dead” buttons |
| Long tasks | progress or indeterminate + cancel when safe |

- Prefer **skeletons** when layout is known; use **spinners** when structure is unknown or spinners are the established pattern.
- **Disabled** controls need a reason (tooltip, helper text, or upcoming availability)—not silently inert.

## 3) Structure and hierarchy

- **Visual order** matches **reading and task order** (especially under RTL - right-to-left).
- Group related controls; separate groups with **spacing**, not redundant chrome.
- **Progressive disclosure**: advanced or risky options collapsed or behind clear entry points.
- **Copy**: concrete, action-oriented; avoid internal codenames in user-facing strings.

## 4) Accessibility and inclusion

- **Semantic structure**: headings, lists, landmarks, and roles that match intent (use platform accessibility APIs where appropriate).
- **Keyboard / focus**: visible focus; tab order matches visual order; no keyboard traps in modals without escape.
- **Contrast**: text and interactive elements meet **AA - WCAG conformance level AA** against their backgrounds; do not rely on **color alone** for status (pair with icon, text, or pattern).
- **Touch targets**: aim for at least ~44×44 logical pixels/points where possible; maintain spacing between interactive items.
- **Motion**: respect reduced motion; do not convey meaning with motion alone.
- **Images**: provide meaningful alt/labels when informative; mark decorative media appropriately.

## 5) Predictable interactions

- Match **platform and in-app** patterns before inventing new ones.
- **Same control, same behavior** across screens.
- Preserve work: drafts, navigation back, non-destructive defaults where appropriate.
- **Destructive** actions: confirm, make consequences obvious, prefer undo when feasible.

## 6) Validation and error recovery

- Constrain input early (format, length) when it prevents costly mistakes.
- **Errors**: what broke, why (when useful), **how to fix**; associate messages with fields.
- **Global summaries** optional for long forms; link to fields.
- Offer **retry** and support paths for server or network failures.

## 7) Verify before shipping

- Walk the **happy path** and at least one **failure path**.
- Check **small and large** viewports; verify both RTL - right-to-left and LTR - left-to-right where applicable.
- Confirm no missing states, no silent errors, no ambiguous primary **CTA - call to action**.

## Anti-patterns

- **Hardcoded visual values** instead of design tokens for standard UI.
- **Ambiguous CTAs - calls to action** (“Submit”, “Continue”) without task context.
- **Placeholder as label**; weak or missing field labels.
- **Critical actions** only as obscure icons without labels.
- **Spinners** on long jobs with no progress or cancel.
- **Modals** for tasks that need comparison, multi-step review, or reference to underlying content.
- **Layout** that breaks under RTL - right-to-left because of absolute LTR - left-to-right assumptions.

## Quick implementation checklist

- Apply design tokens for color, typography, spacing, and elevation.
- Prefer shared components for common patterns (buttons, inputs, cards, dialogs, navigation).
- Validate directionality for mirrored layouts and directional icons.
- Verify focus visibility and keyboard reachability where applicable.
- Ensure loading, empty, error, and success states are implemented and testable.

## Additional resources

- **WCAG - Web Content Accessibility Guidelines**–oriented **spot-check** and success-criteria reminders: [reference.md](reference.md)
