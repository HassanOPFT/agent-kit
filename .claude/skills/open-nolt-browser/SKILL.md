---
name: open-nolt-browser
description: >-
  Opens local Nolt in Google Chrome (macOS). Use after run-nolt, or when the user
  asks to open Nolt in Chrome / the browser. Defaults to http://localhost:3000.
---

# Open Nolt in Google Chrome

Open the running Nolt UI in **Google Chrome**. Do not start the server here —
use **`run-nolt`** first if nothing is listening.

## Default URL

`http://localhost:3000` (dev server or `scripts/build-and-run-nolt.sh`)

Use `http://localhost:5173` when Nolt was started with `docker compose` `app-dev`.

## Check then open

```bash
URL="${NOLT_URL:-http://localhost:3000}"
# Derive port from URL for the listen check when possible; else assume 3000
lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1 || lsof -Pi :5173 -sTCP:LISTEN -t >/dev/null 2>&1
```

If nothing is listening: report `open-nolt-browser: failed — Nolt not listening; run run-nolt first` and stop.

## macOS Chrome

```bash
URL="${NOLT_URL:-http://localhost:3000}"
open -a "Google Chrome" "$URL"
```

Fallback if `open -a` fails:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "$URL" >/dev/null 2>&1 &
```

Do not use Chromium or Safari unless the user asks.

## Closing line

`open-nolt-browser: opened — <url>`  
or `open-nolt-browser: failed — <reason>`
