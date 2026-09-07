---
name: noon-mysql
description: >-
  Run read-only MySQL queries against noon2_core on local Docker, dev, staging,
  or prod (writes gated). Use when the agent needs DB rows, counts, or id
  lookups; when debugging with live data; or when the user asks to query
  MySQL / DBeaver-equivalent without the GUI. Default harness blocks
  modifications even if the DB user has write grants. Requires playground/.env;
  remote envs need pritunl-vpn first. Prefer native client, then Docker client
  fallback (start/stop Docker Desktop if needed) — do not stop after one path.
---

# noon MySQL query

Fetch data from `noon2_core` without DBeaver. Prefer this skill over inventing
ad-hoc `docker exec` / `mysql` one-liners.

**Do not report blocked** until both remote client paths have failed (native
Homebrew `mysql-client`, then Docker `mysql:8.0` client). VPN/tunnel is still
required to reach remote hosts.

## Paths

| Item | Path |
| --- | --- |
| Runner | `playground/bin/noon_mysql.sh` |
| VPN helper | `playground/bin/pritunl_vpn.sh` (skill **pritunl-vpn**) |
| Credentials | `playground/.env` (`LOCAL_/DEV_/STAGING_/PROD_CORE_DB_*`) |
| Example env | `playground/.env.example` |

Never print `*_PASSWORD` values or dump `.env` into chat.

## Safety harness (default)

Defense in depth — **assume credentials may allow writes**:

1. **Client SQL gate** — only `SELECT` / `WITH` / `SHOW` / `DESCRIBE` / `DESC` / `EXPLAIN`; single statement; no `INTO OUTFILE`/`DUMPFILE`; no `FOR UPDATE` / `LOCK IN SHARE MODE`
2. **Session** — `SET SESSION transaction_read_only=ON` so MySQL rejects DML/DDL even when GRANTs allow them
3. **prod** — writes never unlocked

Do not bypass the harness for agent exploration. Prefer staging/local reads.

## Targets

| `--env` | How it connects | Writes |
| --- | --- | --- |
| `local` | Docker container `mysql` (run **docker-deps** first) | Gate: `NOON_MYSQL_WRITE_OK=1` (also turns off session RO) |
| `dev` | VPN (+ SSH tunnel fallback via `ops.noonops.net`) | Gate: `NOON_MYSQL_WRITE_OK=1` |
| `staging` | VPN (+ tunnel if direct TCP fails) | Gate: `NOON_MYSQL_WRITE_OK=1` |
| `prod` | VPN + **SSH tunnel via `ops.noonops.net` by default** | **Forbidden** |

Default for agent lookups: **`staging`** or **`local`**. Use **`prod`** only when the user asks for prod data (or when debugging a clear prod incident).

## Client choice (remote) — dual path, no early stop

For `dev` / `staging` / `prod`, try clients in order. **Do not give up after path 1.**

| Order | Client | When |
| --- | --- | --- |
| 1 | Homebrew `mysql-client` (`brew install mysql-client`) | Default — ships `mysql_native_password.so` |
| 2 | Docker `mysql:8.0` one-shot container | If native missing, auth **2059**, or other **connectivity/auth** client failure |

The runner (`noon_mysql.sh`) already falls back path 1 → 2 for connectivity/auth failures.
It does **not** retry Docker for pure SQL errors (e.g. unknown column).

### Docker Desktop for client fallback

If the Docker **daemon** is down when path 2 is needed:

1. Start Docker Desktop (`open -a Docker` / `open -a "Docker Desktop"`).
2. Wait until `docker info` succeeds (up to ~3 minutes).
3. Run the query via `NOON_MYSQL_FORCE_DOCKER=1` (or let the script fall back).
4. If **this session started** Docker Desktop, quit it afterward (`osascript` quit Docker / Docker Desktop) so it does not stay running only for the agent.

The runner auto-starts and auto-quits Docker Desktop when it starts the daemon for fallback.

Avoid the Homebrew **`mysql` / `mysql@9` server CLI** for remote — it often fails with 2059.

| Env | Needs Docker? |
| --- | --- |
| `local` | Yes — **docker-deps** `mysql` container (`docker exec`) |
| `dev` / `staging` / `prod` | Prefer native; start Docker Desktop only for client fallback |

Overrides: `NOON_MYSQL_BIN=/path/to/mysql`, `NOON_MYSQL_FORCE_DOCKER=1`.

## Workflow

1. Confirm `playground/.env` has the needed `*_CORE_DB_*` keys (see `.env.example`). If missing, tell the user to copy `.env.example` → `.env` and fill values once — do not ask them to paste passwords in chat.
2. For `local`: ensure **docker-deps** (`mysql` healthy).
3. For `dev`/`staging`/`prod`:
   - Run **pritunl-vpn** until ready when possible (or `--skip-vpn` if the user confirms VPN is up / tunnel already open).
   - Prefer `--tunnel` for prod (script default).
   - Try native client first; on connectivity/auth failure, use Docker client (start Docker Desktop if needed, then stop if you started it).
4. Run the query via the script.
5. Summarize rows for the user; do not dump huge result sets — add `LIMIT` when exploring.
6. After remote work, stop leftover SSH tunnels on `NOON_MYSQL_TUNNEL_PORT` (default `13306`) if you opened them for a one-off debug.

## Commands

```bash
# Local
playground/bin/noon_mysql.sh --env local --sql 'SELECT COUNT(*) FROM profile'

# Staging (typical remote read)
playground/bin/noon_mysql.sh --env staging --sql 'SELECT COUNT(*) FROM profile LIMIT 5'

# Prod (read-only enforced; tunnel by default)
playground/bin/noon_mysql.sh --env prod --sql 'SELECT 1'

# Force Docker client (starts Docker Desktop if daemon down, quits if script started it)
NOON_MYSQL_FORCE_DOCKER=1 playground/bin/noon_mysql.sh --env prod --tunnel --skip-vpn --sql 'SELECT 1'

# From file / stdin
playground/bin/noon_mysql.sh --env staging --file /tmp/q.sql
echo 'SHOW TABLES LIKE "profile"' | playground/bin/noon_mysql.sh --env local
```

Optional:

- `MYSQL_HEADERS=1` — keep column names
- `--tunnel` — force SSH LocalForward through `ops.noonops.net` (same bastion DBeaver uses; key default `~/.ssh/id_ed25519`)
- `--skip-vpn` — skip VPN ensure (already connected / debugging)
- `NOON_SSH_USER` — bastion SSH login (default `hassan` for `ops.noonops.net`; same as DBeaver SSH User Name)
- `NOON_MYSQL_PROD_DIRECT=1` — skip default prod tunnel (rarely needed)
- `NOON_MYSQL_BIN` — force a mysql client binary
- `NOON_MYSQL_FORCE_DOCKER=1` — skip native client; use Docker `mysql:8.0`

## Write gate

Non-SELECT on local/dev/staging only, after explicit user OK:

```bash
NOON_MYSQL_WRITE_OK=1 playground/bin/noon_mysql.sh --env local --sql 'UPDATE …'
```

This turns **off** session `transaction_read_only`. Show the SQL to the user first. Never use the gate for prod.

## Failures → next action

| Failure | Next action |
| --- | --- |
| harness refused / multi-statement | Rewrite as a single read-only statement |
| `transaction_read_only` / cannot execute | Expected for DML under default harness |
| missing `*_CORE_DB_*` | Fill `playground/.env` from `.env.example` |
| local container missing | Run **docker-deps** |
| native client missing / 2059 / connect fail | Fall back to Docker client; start Docker Desktop if daemon down; quit it if you started it |
| Docker daemon will not start | Report both paths failed; ask user to start Docker Desktop or fix native `mysql-client` |
| VPN probe fail | Run **pritunl-vpn**; if user says VPN is up, retry with `--skip-vpn --tunnel` |
| direct TCP closed | Re-run with `--tunnel` |
| SSH tunnel fail | Set `NOON_SSH_USER`; ensure key is loaded; confirm bastion reachability |
| SQL error (1054, syntax, etc.) | Fix the query — do **not** expect Docker retry to help |
| prod Access denied on direct | Expected — tunnel is default; fix bastion SSH first |
| access denied / limited grants | Expected for some roles — narrow the query or use another env |
| prod non-SELECT | Rewrite as SELECT or use staging/dev |

## Closing line

`noon-mysql: ok env=<env> rows=<n-or-summary>` or `noon-mysql: failed — <reason>`

Only use “blocked” when **native and Docker client paths both failed** (or VPN/tunnel cannot reach the host after both client attempts).

## Related

- **pritunl-vpn** — connectivity
- **docker-deps** — local MySQL **server** container only (separate from remote Docker **client** fallback)
- `api-test-scripts` `noon_mysql_query` — local-only helper inside test suites (prefer this skill for multi-env agent work)
