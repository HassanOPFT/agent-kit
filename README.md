# agent-kit

Reusable Cursor agent skills — copy into any project's `.cursor/skills/` folder or symlink this repo's skills directory.

## Structure

```
.cursor/
  skills/
    clean-code/   # Code quality, SOLID, BUD, performance
    ui-ux/        # UI/UX compass for planning and implementation
```

## Skills

| Skill | Purpose |
|-------|---------|
| **clean-code** | Clean Code, Pragmatic habits, SOLID, BUD optimization, sensible DSA, performance discipline |
| **ui-ux** | UX-first planning and UI implementation compass for any app |

## Usage

**Per project** — copy or link skills into your repo:

```bash
# copy
cp -r .cursor/skills/* /path/to/your-project/.cursor/skills/

# or symlink (Unix)
ln -s /path/to/agent-kit/.cursor/skills /path/to/your-project/.cursor/skills
```

**Personal (all projects)** — copy skills to `~/.cursor/skills/`.

Skills with `disable-model-invocation: false` auto-apply when relevant. Others load when referenced by name.

## Adding skills

Each skill lives in `.cursor/skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`). Keep skills concise; reference other skills when domains overlap (e.g. `clean-code` defers UI/UX to `ui-ux`).
