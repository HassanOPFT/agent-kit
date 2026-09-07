---
name: pritunl-vpn
description: >-
  Ensures the noon Pritunl VPN is up so agents can reach dev/staging/prod
  MySQL and internal hosts. Use before remote DB queries, when
  noon2-core-master.int.dev.noonedu.io is unreachable, or when the user
  mentions Pritunl / VPN for noon. Check-then-connect; never print passwords.
---

# Pritunl VPN (check-then-connect)

Make the noon VPN usable for remote MySQL. Do **not** scrape or print VPN
passwords. Do **not** pass `-p` with a password unless the user explicitly
asked to use a local secret file.

## Paths

| Item | Path |
| --- | --- |
| Helper script | `playground/bin/pritunl_vpn.sh` |
| CLI (optional) | `/Applications/Pritunl.app/Contents/Resources/pritunl-client` |
| App | `/Applications/Pritunl.app` |
| Default probe | `noon2-core-master.int.dev.noonedu.io:3306` |

Override probe with `NOON_VPN_PROBE_HOST` / `NOON_VPN_PROBE_TIMEOUT_SEC`.

## Why probe > CLI list

Electron Pritunl often has **no profiles** in `pritunl-client list`. Treat
**TCP probe success** as the source of truth that the VPN path works.

## 1. Check

```bash
playground/bin/pritunl_vpn.sh status
```

**If exit 0:** report `pritunl-vpn: ready` and stop.

## 2. Ensure (only if down)

```bash
playground/bin/pritunl_vpn.sh ensure
```

This opens the Pritunl app and, if the CLI lists a profile, tries
`pritunl-client start <id> -r`.

**If still down:** tell the user:

> Open Pritunl, connect the noon profile, enter your password, then ask me to retry.

Do not ask them to paste the password into chat.

## 3. Failures → next action

| Failure | Next action |
| --- | --- |
| Probe fails after connect | Confirm correct profile; wait a few seconds; re-run `status` |
| CLI list empty | Normal — use the app UI; probe is enough |
| App missing | Install Pritunl; then re-run |
| Socket / permission errors on CLI | Use the app + probe; run script outside sandbox if needed |

## Closing line

`pritunl-vpn: ready` or `pritunl-vpn: needs human password in app` or `pritunl-vpn: failed — <reason>`

## Related

After VPN is ready, use skill **noon-mysql** to run queries.
