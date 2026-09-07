---
name: upload-private-gist
description: Builds a gh CLI command to upload user-provided files as a secret (private) GitHub gist. Outputs the command only—never runs it. Use when the user wants to gist files, upload to a private gist, share config via gist, or attaches files under .cursor/.
disable-model-invocation: true
---

# Upload Private Gist

Upload user-supplied files to a **secret** GitHub gist by giving them a ready-to-run `gh` command. **Never execute** gist, git, or shell commands for this workflow.

## When invoked

1. **Collect files** from the user message:
   - Paths they `@`-mention (often under `.cursor/`, e.g. rules, skills, hooks).
   - Explicit paths they list.
   - If no files are given, ask which paths to include (one gist per invocation).

2. **Validate paths** (read-only checks only):
   - Resolve paths relative to the workspace root.
   - Confirm each file exists; skip directories unless the user asked to bundle a folder (then list files explicitly).
   - If a path is missing, say so and ask for a correction—do not invent paths.

3. **Optional gist metadata** (use defaults if omitted):
   - **Description**: short phrase from filenames or user intent; pass via `--desc`.
   - If the user gave a description verbatim, use it as-is.

4. **Output only** — see [Output format](#output-format). Do not run `gh`, `git`, or upload scripts.

## Gist privacy

GitHub “private” gists are **secret** gists: unlisted, reachable only with the URL. Do **not** pass `-p` / `--public`.

Default command shape:

```bash
gh gist create --desc "<description>" <file1> <file2> ...
```

Use workspace-relative paths in the command so the user can run it from the repo root.

## Prerequisites (mention once per response)

- [GitHub CLI](https://cli.github.com/) installed (`gh`)
- Authenticated: `gh auth status` (user runs this themselves)

Do not run `gh auth login` or `gh gist create` on the user's behalf.

## Output format

Reply with exactly this structure (adjust content, keep sections):

```markdown
## Private gist upload

**Files**
- `path/to/file1`
- `path/to/file2`

**Prerequisites:** `gh` installed and logged in (`gh auth status`).

**Run from repo root:**

\`\`\`bash
gh gist create --desc "Your description here" path/to/file1 path/to/file2
\`\`\`

After you run it, `gh` prints the secret gist URL. Open it with:

\`\`\`bash
gh gist view <gist-id> --web
\`\`\`

(or use the URL from the create output)
```

### Rules

- One copy-pastable `gh gist create` block; paths in the same order as the file list.
- Quote `--desc` when it contains spaces or special characters.
- If a single file: still use `gh gist create --desc "..." path`.
- For many files (>10), still one command unless the user asked to split; note total size if files look huge.
- **Never** run the command, suggest auto-running it, or use the Shell tool for gist upload.
- **Never** read file contents into the chat unless the user asked to preview; listing paths is enough.

## Examples

**User:** `@.cursor/rules/foo.md @.cursor/skills/bar/SKILL.md` → gist these

**Output command:**

```bash
gh gist create --desc "Cursor rules and bar skill" .cursor/rules/foo.md .cursor/skills/bar/SKILL.md
```

**User:** upload `hooks.json` from `.cursor/` with description `noon hooks backup`

```bash
gh gist create --desc "noon hooks backup" .cursor/hooks.json
```
