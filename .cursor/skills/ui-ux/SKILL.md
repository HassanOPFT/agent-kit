---
name: ui-ux
description: Guides UI and UX decisions during planning and implementation for any app. Use when designing screens, flows, features, or reviewing interface work. Reference from other skills when UI/UX quality matters.
disable-model-invocation: false
---

# UI/UX Compass

Apply during **planning and implementation** for any app (web, mobile, dashboard, internal tool). UX before polish. Clarity over cleverness.

Other skills may defer UI/UX judgment here: *"Follow the ui-ux skill for interface and flow decisions."*

---

## When to apply

- Planning a feature, screen, or flow
- Implementing UI components or pages
- Reviewing interface work before finishing
- User reports confusion, friction, or accessibility issues

---

## UX compass (plan first)

Before building, clarify:

| Question | Goal |
|----------|------|
| Who is the user? | Know context, skill level, constraints |
| What job are they doing? | One primary outcome per flow |
| What is the happy path? | Shortest path to success |
| What can go wrong? | Errors, empty, loading, denied, offline |
| What must they remember? | Minimize memory load between steps |

**Flow rules**

- One primary action per screen; secondary actions visually subordinate
- Progressive disclosure: show only what the current step needs
- Labels in user language, not system jargon
- Every action gets feedback (success, failure, in-progress)
- Errors state what happened and how to fix — near the source
- Empty states explain what to do next, not just "No data"
- Do not make users hunt for undo, cancel, or back

**Accessibility (requirements, not optional polish)**

- Keyboard reachable; visible focus
- Text alternatives for non-text content
- Sufficient contrast; do not rely on color alone
- Touch targets large enough for the platform
- Respect reduced-motion preferences

---

## UI compass (while building)

**Hierarchy:** The most important element dominates — size, weight, position, or contrast.

**Consistency:** Same action → same control, label, and placement across the app.

**Affordance:** Controls look interactive; static content does not look clickable.

**Grouping:** Related items together; unrelated separated by space or structure.

**Typography:** Limited scale; body text readable without zoom; avoid long lines.

**Spacing:** Regular rhythm; generous padding on interactive elements.

**States:** Design all of — default, hover, focus, active, disabled, loading, error.

**Responsive:** Works on the smallest target device; no horizontal scroll for core content.

---

## Decision heuristics

Use these when choosing between options:

1. **Clarity beats cleverness** — if a user hesitates, the design failed
2. **Fewer choices per step** — split complex tasks into steps
3. **Defaults over blanks** — pre-fill sensible values when safe
4. **Prevent before correct** — disable invalid actions; validate early
5. **Reversible over destructive** — confirm irreversible actions; offer undo when possible
6. **Show, don't hide** — critical info visible; avoid mystery icons and hidden menus for core tasks
7. **Match mental models** — use familiar patterns for the platform
8. **Reduce friction on the primary path** — optimize the common case first

---

## Planning output (brief)

When scoping UI work, state before coding:

```
User:
Primary job:
Primary action:
Key states: [empty, loading, error, success]
Accessibility notes:
Open questions:
```

Skip fields that are obvious from context.

---

## Review gate

Before marking UI work done:

- [ ] Primary action obvious within 3 seconds?
- [ ] Happy path completable without instructions?
- [ ] Empty, loading, and error states handled?
- [ ] Error messages actionable?
- [ ] Keyboard and focus usable?
- [ ] Consistent with existing app patterns?
- [ ] Works on smallest target viewport?

If not, fix in scope before done.

---

## Review feedback format

When critiquing UI/UX:

```
**Issue:** [what fails for the user]
**Principle:** [which heuristic above]
**Fix:** [concrete change]
```

---

## Anti-patterns

Avoid unless explicitly required:

- Mystery meat navigation (icons with no labels for core actions)
- Disabled submit with no explanation
- Generic errors ("Something went wrong")
- Modals stacked on modals
- Required fields not marked until submit fails
- Low-contrast placeholder-as-label text
- Infinite scroll with no search/filter for long lists
- Auto-advancing carousels on critical content
- Breaking browser back / platform navigation expectations

---

## Scope boundary

This skill is a **compass**, not a design system. Do not prescribe brand colors, fonts, or component libraries. Match project conventions when they exist; otherwise apply the principles above.
