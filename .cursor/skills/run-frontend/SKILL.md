---
name: run-frontend
description: >-
  Starts a noon2-frontend webpack app (admin/facilitator/teacher/student/…)
  against local or remote API. Use when the user asks to run/open admin (or
  another FE package), yarn web, localhost:8089, or debug missing flags/pages
  because FE may be pointed at the wrong backend. Always choose local vs
  dev from context before starting; plain yarn web defaults to dev.
---

# Run frontend (pick backend target first)

**Scope:** workspace / `agent-config` local skills. Do **not** commit under
shared `noon2-frontend` `.claude/` unless the team adopts it.

Webpack loads `packages/common/noonConfig.<environment>.ts`. **Wrong target
is the usual reason** feature flags, seed data, or pages “don’t show” while
local BE is fine.

## 1. Choose `environment` from context

| Intent | Webpack `environment` | API (`baseUrl`) | Also need |
| --- | --- | --- | --- |
| Local BE / local DB flags / local smoke | **`local`** | `http://localhost:8082/noon2-core` | **run-backend** (+ docker-deps, auth-port-forward) |
| Hit shared **dev** API (no local core) | **`dev`** (default) | `https://backend.dev.noonedu.io/noon2-core` | VPN only if calls fail / internal hosts |
| Staging / prod configs | `staging` / `prod` | matching `noonConfig.*` | **pritunl-vpn**; never invent prod writes |

**How to decide:**

- User says local, bootRun, local MySQL, local flags, “against my BE” → **`local`**
- User says dev backend, QA data on remote, no local core → **`dev`**
- Ambiguous → **ask**. Do not assume local.
- If a server is already up, **verify** its `baseUrl` (below) before starting another.

`noonConfig.local` may set `env: 'qa'` for telemetry — that is **not** the webpack
environment. Always judge by **`baseUrl`**, not `CONFIG.env`.

## 2. Packages / ports

| Package | Port | Typical local URL |
| --- | --- | --- |
| admin | 8089 | http://localhost:8089 |
| student | 8081 | http://localhost:8081 |
| teacher | 8085 | http://localhost:8085 |
| presenter | 8087 | http://localhost:8087 |
| facilitator | 8092 | http://localhost:8092 |
| genai | 8095 | http://localhost:8095 |

Default when user says “admin” / “FE for school ops”: **admin**.

## 3. Pitfall: plain `yarn web` = **dev**

Every package `webpack.config.js`:

```js
env?.environment ?? (argv.mode === 'production' ? undefined : 'dev');
```

So `yarn web` with no `--env` → **`noonConfig.dev`**, not local.

Do **not** use `yarn web -- --env environment=local` — the bare `--` can break
webpack-cli (`entry[0] should be a non-empty string`). Prefer invoking webpack
via the monorepo bin (below).

## 4. Check what is already running

```bash
PORT=8089   # admin; change per package
lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 && LISTENING=1 || LISTENING=0

# Required: which API is baked into the HTML
curl -s "http://localhost:$PORT/" | python3 -c '
import sys,re
h=sys.stdin.read()
for k in ("baseUrl","b2bHost","env"):
  m=re.search(r"\"%s\":\"([^\"]+)\"" % k, h)
  print("%s=%s" % (k, m.group(1) if m else "MISSING"))
'
```

| `baseUrl` contains | Meaning |
| --- | --- |
| `localhost:8082` | **local** — OK for local BE work |
| `backend.dev.noonedu.io` | **dev** — OK only if that was intended |
| other | confirm with user |

**If listening but wrong target:** kill the listener on that port, then start
with the correct `environment`. Do not tell the user to “hard refresh” alone —
config is compile-time via HtmlWebpackPlugin.

**If listening and correct target:** report already running and stop.

## 5. Run

From the package directory (example: admin + **local**):

```bash
cd /path/to/noon2-frontend/packages/admin
sh ../../scripts/version_vars .
WEBPACK_BIN=./node_modules/.bin/webpack
[ -x "$WEBPACK_BIN" ] || WEBPACK_BIN=../../node_modules/.bin/webpack
"$WEBPACK_BIN" serve --mode=development --config webpack.config.js --port 8089 --env environment=local
```

**dev** (explicit; same as default `yarn web`):

```bash
"$WEBPACK_BIN" serve --mode=development --config webpack.config.js --port 8089 --env environment=dev
# or: yarn web
```

Background when the user needs the shell free. Wait for
`compiled successfully` / Loopback URL, then re-check `baseUrl` (step 4).

For **local**, confirm BE: `curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8082/actuator/health` → `200`. If not, run **run-backend** first.

## 6. Failures → next action

| Failure | Next action |
| --- | --- |
| Flags / School nav missing; BE local looks fine | Verify FE `baseUrl` — often still on **dev** |
| Port busy | Kill wrong webpack or pick another port |
| `Invalid configuration` / empty `entry` after `yarn web -- --env …` | Use webpack bin + `--env environment=…` (no bare `--`) |
| Local API connection refused | **run-backend** (and prereqs) |
| Dev API unreachable | **pritunl-vpn**; confirm network |
| Login / auth errors on local | **auth-port-forward** + **local-auth** |

## Closing line

`run-frontend: already running — <package> :<port> → <baseUrl>`  
or `run-frontend: started — <package> :<port> → <baseUrl>`  
or `run-frontend: failed — <reason>`
