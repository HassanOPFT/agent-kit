# agent-kit

Reusable Cursor / Claude Code agent skills and agents — copy into any project's `.cursor/` (or `.claude/`) folder, or symlink this repo's directories.

## Structure

```
.cursor/
  skills/     # Cursor skills (unique, deduped)
  agents/     # Cursor agent definitions
.claude/
  skills/     # Same skills mirrored for Claude Code
  agents/     # Claude Code agent definitions
.agents/
  skills/     # Codex-style agent skills (subset)
```

See [SKILLS.md](./SKILLS.md) for the full inventory and source paths.

## Skills

Skills cover workflows such as: clean code, UI/UX, PR/commit flows, backend checks, local auth, Docker/EKS/MySQL helpers, content generation, and project-specific ops (activities, nolt, migrations).

## Usage

**Per project** — copy or link:

```bash
# copy skills
cp -r .cursor/skills/* /path/to/your-project/.cursor/skills/

# copy agents
mkdir -p /path/to/your-project/.cursor/agents
cp -r .cursor/agents/* /path/to/your-project/.cursor/agents/

# or symlink (Unix)
ln -s /path/to/agent-kit/.cursor/skills /path/to/your-project/.cursor/skills
ln -s /path/to/agent-kit/.cursor/agents /path/to/your-project/.cursor/agents
```

**Personal (all projects)** — copy skills to `~/.cursor/skills/`.

Skills with `disable-model-invocation: false` auto-apply when relevant. Others load when referenced by name.

## Adding skills

Each skill lives in `.cursor/skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`). Keep skills concise; reference other skills when domains overlap.

Mirror the same skill under `.claude/skills/` when Claude Code should see it too.

## Agents

Agent definitions live as markdown under `.cursor/agents/` and `.claude/agents/` (for example `execute-plan.md`).
