#!/usr/bin/env bash
# Auth helper template. Copy to <project>/api-test-scripts/auth/auth.sh and adapt.
# Sets ACCESS_TOKEN for api_runner_ensure_auth.
#
# Default assumes JSON login:
#   POST ${AUTH_LOGIN_PATH:-/auth/login}
#   body: { "email": "...", "password": "..." }
#   token at jq path ${AUTH_TOKEN_JQ:-.accessToken}

api_auth_resolve_access_token() {
  if [[ -n "${ACCESS_TOKEN:-}" ]]; then
    return 0
  fi

  : "${BASE_URL:?BASE_URL required}"
  local login_path="${AUTH_LOGIN_PATH:-/auth/login}"
  local token_jq="${AUTH_TOKEN_JQ:-.accessToken}"
  local email="${AUTH_EMAIL:-${AUTH_USERNAME:-}}"
  local password="${AUTH_PASSWORD:-}"

  if [[ -z "$email" || -z "$password" ]]; then
    echo "api_auth_resolve_access_token: set ACCESS_TOKEN or AUTH_EMAIL/AUTH_PASSWORD" >&2
    return 1
  fi

  local body raw code token
  body="$(jq -cn --arg email "$email" --arg password "$password" \
    '{email:$email,password:$password}')"

  raw="$(curl -sS -w "\n%{http_code}" -X POST "${BASE_URL%/}${login_path}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$body" || true)"
  code="$(printf '%s' "$raw" | tail -n1)"
  body="$(printf '%s' "$raw" | sed '$d')"

  if [[ "$code" != "200" && "$code" != "201" ]]; then
    echo "api_auth_resolve_access_token: login HTTP ${code}" >&2
    printf '%s\n' "$body" >&2
    return 1
  fi

  token="$(printf '%s' "$body" | jq -er "$token_jq")"
  ACCESS_TOKEN="$token"
  export ACCESS_TOKEN
}
