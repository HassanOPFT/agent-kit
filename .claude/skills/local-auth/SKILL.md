---
name: local-auth
description: >-
  Log into local noon2-core with username/password (hassan / hassan@noon),
  switch profiles (school manager, facilitator, admin), and export ACCESS_TOKEN
  for API scripts. Use when calling local APIs that need a JWT. Requires
  auth-port-forward on 8771 and run-backend on 8082.
---

# Local auth (username + password)

**Scope:** lives in `agent-config` (local workspace). Do **not** copy into shared
`noon2_core` `AGENTS.md`.

Log into **local** noon2-core with the shared dev account and optional profile
switch. Uses `api-test-scripts/auth/auth.sh`.

## Prerequisites

Run these skills first (or confirm they are already up):

1. **docker-deps** — MySQL and deps
2. **auth-port-forward** — `http://localhost:8771` healthy
3. **run-backend** — `http://localhost:8082/noon2-core`

## One-time credentials file

Create `api-test-scripts/auth/.env` (gitignored):

```bash
BASE_URL=http://localhost:8082/noon2-core
AUTH_USERNAME=hassan
AUTH_PASSWORD=hassan@noon
```

Never commit `auth/.env`. See `auth/auth.env.example` for all keys.

## Quick login (shell)

```bash
API_ROOT="/path/to/api-test-scripts"   # adjust to your workspace
source "${API_ROOT}/auth/.env"
source "${API_ROOT}/auth/auth.sh"

# Default login uses AUTH_USER_TYPE / AUTH_APP_TYPE from .env (ADMIN).
noon_auth_resolve_access_token || exit 1
echo "ACCESS_TOKEN length: ${#ACCESS_TOKEN}"
echo "profiles: ${NOON_AUTH_PROFILE_COUNT}"
```

## Profile switch

After password login, `NOON_AUTH_ACCOUNT_JSON` and `NOON_AUTH_PROFILES_JSON` are
set. Call `noon_auth_switch_profile` with the profile id and `app-type`.

**Local hassan account (typical IDs — verify with `NOON_AUTH_PROFILES_JSON`):**

| Role | Profile ID | Login `AUTH_USER_TYPE` | Switch `app-type` |
| --- | --- | --- | --- |
| Admin | 1366 | ADMIN | ADMIN |
| Facilitator | 1569 | FACILITATOR | SCHOOL |
| School manager | 1574 | SCHOOL_MANAGER | SCHOOL |
| School lead | 1573 | SCHOOL_LEAD | SCHOOL |

Example — facilitator token for school API:

```bash
AUTH_USER_TYPE=FACILITATOR
AUTH_APP_TYPE=SCHOOL
noon_auth_resolve_access_token || exit 1
noon_auth_switch_profile 1569 SCHOOL || exit 1
# ACCESS_TOKEN is now scoped to facilitator profile 1569
```

Example — school manager:

```bash
AUTH_USER_TYPE=SCHOOL_MANAGER
AUTH_APP_TYPE=SCHOOL
noon_auth_resolve_access_token || exit 1
noon_auth_switch_profile 1574 SCHOOL || exit 1
```

## Browser login (no password fill)

Cursor Smart Mode blocks agents from filling password fields. **Do not** use
`browser_fill` on password inputs for local testing. Never ask the user to type
the local password when `api-test-scripts/auth/.env` already has credentials.

**One-time setup (human):** ensure `api-test-scripts/auth/.env` exists with
`AUTH_USERNAME` / `AUTH_PASSWORD` (see `auth.env.example`). Agents must not
print those values.

**Session inject (agent default for facilitator web):**

```bash
API_ROOT="/path/to/api-test-scripts"
# shellcheck source=/dev/null
source "${API_ROOT}/auth/.env"
# shellcheck source=/dev/null
source "${API_ROOT}/auth/auth.sh"
PROFILE_ID=1574 APP_TYPE=SCHOOL "${API_ROOT}/auth/facilitator_browser_session.sh"
# Writes /tmp/noon-facilitator-browser-session.json (mode 600). Do not cat the file.
```

Then in the Cursor browser on `http://localhost:8092`:

1. Navigate to `http://localhost:8092/login` (or any facilitator origin).
2. Run page JS (CDP / evaluate) that reads **only** the `persistRoot` string from
   that JSON file via a shell-produced one-liner, or pass `persistRoot` without
   logging it:

```js
// Agent must load persistRoot from the session file without printing tokens.
localStorage.setItem('persist:root', persistRoot);
location.assign(targetPath); // e.g. /room-details/410/settings
```

`useSignedIn` requires **both** `persisted.profile.profile` and
`persisted.connection.tokens`. The helper writes both into `persistRoot`.

| Role | PROFILE_ID |
| --- | --- |
| School manager | 1574 |
| Facilitator | 1569 |
| School lead | 1573 |

## Authorization header (critical)

noon2-core expects the **raw JWT** in `Authorization`, **not** `Bearer <token>`.

```bash
curl -H "Authorization: ${ACCESS_TOKEN}" \
  -H "app-type: SCHOOL" \
  -H "device-id: local-auth" \
  -H "platform: WEB" \
  -H "country-code: AE" \
  "${BASE_URL}/school/cohorts/my-homerooms"
```

Using `Bearer` returns **401** on protected routes.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Login 400 / connection refused | Run **auth-port-forward** (one-shot `pf-auth`, then a **persistent** `kubectl` forward if health drops); check `NOON2AUTH_HOST=http://localhost:8771` in backend `.env` |
| 401 on API after login | Remove `Bearer ` prefix from `Authorization` header |
| switchProfile 404 | Use account id from login (`NOON_AUTH_ACCOUNT_JSON.id`, usually **974**) |

## Paths

| Item | Path |
| --- | --- |
| Auth lib | `api-test-scripts/auth/auth.sh` |
| Facilitator browser session | `api-test-scripts/auth/facilitator_browser_session.sh` |
| Credentials example | `api-test-scripts/auth/auth.env.example` |
| Host JVM env | `local-custom/HOST_BOOTRUN.md` |
