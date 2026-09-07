---
name: run-nolt
description: >-
  Starts local Nolt (nolt.diy) for noon activity authoring. Prefers check-then-run
  on port 3000: npm/pnpm dev for current branch work, or the workspace Docker
  script scripts/build-and-run-nolt.sh for a containerized build. Use when the
  user asks to run nolt, start nolt locally, build-and-run-nolt, or open Nolt
  for Open Activity / activity preview testing.
---

# Run Nolt (check-then-run)

Start **nolt.diy** locally. Do **not** print `.env.local` secrets.

After the app is up, load **`open-nolt-browser`** to open Google Chrome unless the
user said not to open a browser.

## Paths

| Item | Path / value |
| --- | --- |
| App repo | `nolt.diy` (this repo) |
| Workspace root | parent of `nolt.diy` (sibling of `scripts/`) |
| Env file | `nolt.diy/.env.local` (required for LLM keys; copy from `.env.example` if missing) |
| Fast / branch UI | `npm run dev` or `pnpm run dev` → **http://localhost:3000** |
| Workspace Docker script | `../scripts/build-and-run-nolt.sh` → image `nolt-local:fix`, container `nolt-local-fix`, **http://localhost:3000** |
| Compose alternate | `docker compose --profile development up` in `nolt.diy` → **http://localhost:5173** |

## Which mode

| Goal | Mode |
| --- | --- |
| Test current git branch / Open Activity UI | **dev server** (`npm run dev`) — serves live source |
| Containerized build matching team script | **Docker script** `scripts/build-and-run-nolt.sh` |
| Compose HMR bind-mount | **compose** `app-dev` on 5173 |

Default when the user just says “run nolt”: **dev server** if `node_modules` exists;
otherwise Docker script (or install deps first).

## 1. Prerequisites

1. Docker Desktop only required for Docker script / compose modes.
2. `.env.local` present under `nolt.diy`. If missing: copy `.env.example` → `.env.local` and tell the user to fill API keys (do not invent keys).
3. For Open Activity / Try it / Share links: remote **dev** hosts (`student.dev`, `teacher.dev`, `acts.dev`) are used — local noon2_core is **not** required for that UI.

Stop if `.env.local` is missing and keys are needed; report next action.

## 2. Check if already running

```bash
lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1 && LISTENING_3000=1 || LISTENING_3000=0
lsof -Pi :5173 -sTCP:LISTEN -t >/dev/null 2>&1 && LISTENING_5173=1 || LISTENING_5173=0
docker ps --format '{{.Names}}' | grep -q '^nolt-local-fix$' && DOCKER_NOLT=1 || DOCKER_NOLT=0
```

**If already serving Nolt on 3000 or 5173 (or `nolt-local-fix` is up):** report
`run-nolt: already running — http://localhost:<port>` and run **open-nolt-browser**
with that URL. Do not start a second instance.

## 3. Run — dev server (default for branch work)

From `nolt.diy`:

```bash
cd /path/to/nolt.diy
# prefer pnpm if lockfile / corepack says so; npm run dev is fine when package scripts match
npm run dev
```

Vite listens on **3000** (`vite.config.ts`). Run in the background; wait until the
log shows the local URL (or `lsof` on 3000).

## 4. Run — workspace Docker script

From **workspace root** (directory that contains both `nolt.diy` and `scripts/`):

```bash
cd /path/to/noon_workspace
./scripts/build-and-run-nolt.sh
```

Behavior (see script):

1. `cd nolt.diy`
2. Stop/remove existing container `nolt-local-fix` if present
3. `docker build` with `VITE_*` build-args from `.env.local` → tag `nolt-local:fix`
4. `docker run --rm -p 3000:3000 --env-file .env.local` as `nolt-local-fix`

Rebuild is slow. Use when you need a fresh image from the current tree, not for
tight UI iteration.

Run in the background; wait until port **3000** accepts connections.

## 5. Run — docker compose (optional)

Only if the user asks for compose:

```bash
cd /path/to/nolt.diy
docker compose --profile development up
# or: docker compose --profile production up
```

App URL: **http://localhost:5173**.

## 6. Open browser

Invoke **`open-nolt-browser`** with the URL from the mode you started
(`http://localhost:3000` or `http://localhost:5173`).

## 7. Failures → next action

| Failure | Next action |
| --- | --- |
| Port 3000 busy (not Nolt) | Free the port or use compose on 5173 |
| Missing `.env.local` | Copy from `.env.example`; user fills secrets |
| Docker daemon down | Start Docker Desktop; re-run Docker modes |
| `build-and-run-nolt.sh` not found | Confirm cwd is workspace root next to `nolt.diy` |
| `npm run dev` fails on deps | `npm install` or `pnpm install` in `nolt.diy` |

## Closing line

`run-nolt: already running — http://localhost:<port>`  
or `run-nolt: started — http://localhost:<port> (<dev|docker-script|compose>)`  
or `run-nolt: failed — <reason>`
