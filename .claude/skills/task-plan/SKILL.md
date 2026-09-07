---
name: task-plan
disable-model-invocation: false
description: >-
  Plan a task before coding: survey related features (other repos if needed),
  weigh options with clean-code, pick one, and state the plan in one flowing
  paragraph. Use when the user has a task in hand, wants a plan first, says
  "just plan", "task plan", or attaches this skill before implementation.
---

# Task plan

Plan first. Do not implement until the user locks the plan.

**On start:** load the workspace clean-code skill (`clean-typescript-style` / `clean-code`) and use it for design judgment (YAGNI, KISS, reuse, smallest surface).

## Do

1. Survey related features/patterns in this repo; check other repos when the change crosses them.
2. Weigh 2–4 real options; pick the best fit under clean-code (prefer extend over invent).
3. Stop at the plan when the user only asked to plan.

## Output

`### In one line` — **exactly one flowing paragraph** (no bullets, no sections): how it will work and what we will do. Plain language. Skip filler.

Example tone: “When a teacher reports a Smart Chat bubble we already send `aiMessageId`; we will also put `chatMessageId` and `messageText` in report `meta` (same pattern as annotation grading), so admin can see which message was flagged without a backend change.”
