---
name: auth-port-forward
description: >-
  Ensures noon2auth is reachable on localhost:8771 for local noon2_core.
  Use when bootRun needs auth, login/token calls fail, or NOON2AUTH_HOST
  points at local port-forward. Checks health first; runs pf-auth or a
  persistent kubectl forward only when down.
---

# Auth port-forward (check-then-run)

Make auth reachable at `http://localhost:8771`. Do not start a second
port-forward when one already works.

Local noon2_core does **not** run auth itself. `:8771` is a tunnel to the QA
auth pod (`kubectl port-forward … 8771:10000`).

## One-shot vs persistent

| Mode | What it is | When to use |
| --- | --- | --- |
| **One-shot (`pf-auth.sh`)** | Script starts a forward, waits until health is UP, then **exits**. The tunnel may die when that shell ends, or an old forward may already be gone. | Quick “bring auth up” checks; first attempt when down. |
| **Persistent** | Leave a **long-running** `kubectl port-forward` in a background agent terminal that does **not** exit. `:8771` stays up until that process is killed. | Login / recording / multi-step local work where auth must stay up; when `pf-auth` reports UP but a later health check gets connection refused. |

**Default for agents that need auth to stay alive:** after a failed or flaky one-shot, start a **persistent** forward and leave it running. Do not treat “`pf-auth` exited 0” as proof the tunnel will still be up later — re-check health.

## Paths

From **noon2_core** repo root:

| Item | Path |
| --- | --- |
| Preferred script | `../local-custom/pf-auth.sh` |
| Repo fallback | `scripts/portforward_to_auth.sh` |
| Health URL | `http://localhost:8771/actuator/health` |
| Local port | `8771` |
| Typical pod prefix | `dev-noon2-auth-app-srv` |

`pf-auth.sh` prefers `../api-test-scripts/auth/auth_connectivity.sh` when present;
otherwise it kubectl port-forwards the QA auth pod to `8771`.

## 1. Check

```bash
# Port listening?
lsof -Pi :8771 -sTCP:LISTEN -t >/dev/null 2>&1 && LISTENING=1 || LISTENING=0

# Health — prefer python (avoid curl when workspace security blocks it).
# Look for UP only; do not print the body.
python3 - <<'PY' && HEALTHY=1 || HEALTHY=0
import urllib.request
try:
    body = urllib.request.urlopen("http://localhost:8771/actuator/health", timeout=3).read().decode()
    raise SystemExit(0 if "UP" in body else 1)
except Exception:
    raise SystemExit(1)
PY
```

**If `HEALTHY=1`:** report `auth-port-forward: ready` and stop.

Listening alone is not enough if health fails — free or replace a stale forward (see Failures).

## 2. Run (only if not ready)

### 2a. One-shot first

```bash
cd "$(git rev-parse --show-toplevel)"
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/noon2-eks-qa}"
export AWS_PROFILE="${AWS_PROFILE:-dev}"
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy

if [ -x ../local-custom/pf-auth.sh ]; then
  ../local-custom/pf-auth.sh
elif [ -x scripts/portforward_to_auth.sh ]; then
  ./scripts/portforward_to_auth.sh
else
  echo "NEXT: install kubectl access or check out local-custom beside noon2_core"
  exit 1
fi
```

Re-check health after the script exits.

### 2b. Persistent forward (when one-shot is not enough)

If health is still down, or UP then connection refused on the next check, start a
**background** shell that keeps `kubectl` alive:

```bash
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/noon2-eks-qa}"
export AWS_PROFILE="${AWS_PROFILE:-dev}"
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy
pkill -f 'port-forward.*8771' 2>/dev/null || true
sleep 1
POD=$(kubectl get pods -n default --no-headers 2>/dev/null \
  | awk '/dev-noon2-auth-app-srv/{print $1; exit}')
[ -n "$POD" ] || { echo "NEXT: auth pod not found — refresh kube/aws creds"; exit 1; }
exec kubectl -n default port-forward "pod/$POD" 8771:10000
```

Wait for `Forwarding from` (or health UP), then leave that process running.
Do not start a second forward while this one is healthy.

## 3. Failures → next action

| Failure | Next action |
| --- | --- |
| `kubectl` missing / unauthorized | `aws sso login` (or refresh cluster creds), then re-run |
| Auth pod not found | Confirm kube context and `dev-noon2-auth-app-srv` prefix |
| Port 8771 busy but not healthy | `lsof -i :8771`; stop stale forward, then start persistent |
| `pf-auth` OK then later connection refused | Start **persistent** forward (2b); one-shot does not guarantee the tunnel stays up |
| Script missing | Check out `local-custom` (and optionally `api-test-scripts`) as workspace siblings |

## Closing line

`auth-port-forward: ready` or `auth-port-forward: started` (one-shot) or
`auth-port-forward: persistent` (long-running kubectl left up) or
`auth-port-forward: failed — <reason>`

## Related

For general QA / staging / prod kubectl access, use skill **noon-eks**
(`playground/bin/noon_eks.sh`). This skill stays scoped to local auth `:8771`.
