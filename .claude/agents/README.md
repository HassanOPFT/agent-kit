# Subagents

Claude Code reads custom subagents from `.claude/agents/`. One markdown file per
agent, named however you like (e.g. `.claude/agents/execute-plan.md`), with YAML
frontmatter followed by the agent's system prompt:

```markdown
---
name: execute-plan
description: When to hand work to this agent.
tools: Read, Grep, Glob, Bash, Edit, Write, Agent   # optional; omit to inherit everything
model: sonnet                   # optional
---

The subagent's instructions go here.
```

Cursor mirrors the same files under `.cursor/agents/`.

Built-in agents you don't need to define: `Explore`, `Plan`, `general-purpose`.

## Defined agents

| Agent | File | Role |
|-------|------|------|
| **execute-plan** | `execute-plan.md` | Locked-plan delivery: implement → clean-code loop → API tests (skip live critical externals) → PR → auto-babysit. Contract: `.claude/skills/execute-plan/SKILL.md`. Invoke via agent picker, “execute this plan”, or `/execute-plan`. |
