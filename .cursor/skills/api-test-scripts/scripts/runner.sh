#!/usr/bin/env bash
# Portable API test harness. Copy to <project>/api-test-scripts/lib/runner.sh
# Requires: bash, curl, jq

set -euo pipefail

API_PASSED=0
API_FAILED=0
API_SKIPPED=0
API_SUITE_SLUG=""
API_SUITE_TITLE=""
API_LOG_DIR=""
API_SUMMARY_FILE=""
API_FULL_FILE=""
API_CASE_INDEX=0

api_runner_load_env() {
  local script_dir auth_env scenario_env
  script_dir="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
  # Prefer caller SCRIPT_DIR when sourced from a scenario script
  if [[ -n "${SCRIPT_DIR:-}" ]]; then
    script_dir="$SCRIPT_DIR"
  fi

  auth_env="$(cd "${script_dir}/../auth" && pwd)/.env"
  scenario_env="${script_dir}/.env"

  if [[ -f "$auth_env" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$auth_env"
    set +a
  fi
  if [[ -f "$scenario_env" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$scenario_env"
    set +a
  fi

  : "${BASE_URL:?BASE_URL is required (set in auth/.env or scenario .env)}"
  BASE_URL="${BASE_URL%/}"
  API_AUTH_HEADER="${API_AUTH_HEADER:-Authorization}"
  API_AUTH_SCHEME="${API_AUTH_SCHEME:-Bearer}"
}

api_runner_ensure_auth() {
  if [[ -n "${ACCESS_TOKEN:-}" ]]; then
    return 0
  fi

  local script_dir auth_sh
  script_dir="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)}"
  auth_sh="$(cd "${script_dir}/../auth" && pwd)/auth.sh"

  if [[ ! -f "$auth_sh" ]]; then
    echo "api_runner_ensure_auth: missing ${auth_sh} and ACCESS_TOKEN unset" >&2
    return 1
  fi

  # shellcheck disable=SC1090
  source "$auth_sh"
  if ! api_auth_resolve_access_token; then
    echo "api_runner_ensure_auth: failed to obtain ACCESS_TOKEN" >&2
    return 1
  fi
}

api_runner_init_suite() {
  API_SUITE_SLUG="$1"
  API_SUITE_TITLE="$2"
  API_PASSED=0
  API_FAILED=0
  API_SKIPPED=0
  API_CASE_INDEX=0

  local script_dir
  script_dir="${SCRIPT_DIR:-.}"
  API_LOG_DIR="${script_dir}/logs"
  mkdir -p "$API_LOG_DIR"
  API_SUMMARY_FILE="${API_LOG_DIR}/${API_SUITE_SLUG}_summary.txt"
  API_FULL_FILE="${API_LOG_DIR}/${API_SUITE_SLUG}_full.json"

  {
    echo "# ${API_SUITE_TITLE}"
    echo "base_url=${BASE_URL}"
    echo "started=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo
  } >"$API_SUMMARY_FILE"

  echo "[" >"$API_FULL_FILE"
  echo "Suite: ${API_SUITE_TITLE}"
}

api__token_for_role() {
  local role="$1"
  case "$role" in
    none) echo "" ;;
    default|admin|user)
      echo "${ACCESS_TOKEN:-}"
      ;;
    *)
      local upper var
      upper="$(printf '%s' "$role" | tr '[:lower:]' '[:upper:]')"
      var="ACCESS_TOKEN_${upper}"
      echo "${!var:-${ACCESS_TOKEN:-}}"
      ;;
  esac
}

api__http_match() {
  local expected="$1" actual="$2"
  if [[ "$expected" == *","* ]]; then
    if [[ "${API_ALLOW_MULTI_HTTP:-0}" != "1" ]]; then
      echo "api_run_case: multi HTTP '${expected}' requires API_ALLOW_MULTI_HTTP=1" >&2
      return 1
    fi
    local part
    IFS=',' read -ra parts <<<"$expected"
    for part in "${parts[@]}"; do
      part="$(echo "$part" | tr -d '[:space:]')"
      [[ "$part" == "$actual" ]] && return 0
    done
    return 1
  fi
  [[ "$expected" == "$actual" ]]
}

api__append_full_json() {
  local payload="$1"
  if [[ "$API_CASE_INDEX" -gt 0 ]]; then
    echo "," >>"$API_FULL_FILE"
  fi
  printf '%s\n' "$payload" >>"$API_FULL_FILE"
  API_CASE_INDEX=$((API_CASE_INDEX + 1))
}

api__json_or_string() {
  local raw="$1"
  if [[ -z "$raw" ]]; then
    echo "null"
    return
  fi
  if printf '%s' "$raw" | jq -e . >/dev/null 2>&1; then
    printf '%s' "$raw" | jq -c .
  else
    jq -cn --arg s "$raw" '$s'
  fi
}

# api_run_case branch_id name role method path json_body expected_http [jq_oracle] [skip_if_env_unset]
api_run_case() {
  local branch_id="$1" name="$2" role="$3" method="$4" path="$5" body="${6:-}" expected="$7"
  local oracle="${8:-}" skip_env="${9:-}"

  if [[ -n "$skip_env" && -z "${!skip_env:-}" ]]; then
    API_SKIPPED=$((API_SKIPPED + 1))
    echo "SKIP  ${branch_id} — ${skip_env} unset" | tee -a "$API_SUMMARY_FILE"
    api__append_full_json "$(jq -cn \
      --arg event skip --arg branch_id "$branch_id" --arg name "$name" --arg reason "$skip_env unset" \
      '{event:$event,branch_id:$branch_id,name:$name,reason:$reason}')"
    return 0
  fi

  local token url auth_args=(-sS -w "\n%{http_code}" -X "$method")
  token="$(api__token_for_role "$role")"
  url="${BASE_URL}${path}"

  if [[ "$role" != "none" ]]; then
    if [[ -z "$token" ]]; then
      API_SKIPPED=$((API_SKIPPED + 1))
      echo "SKIP  ${branch_id} — no token for role=${role}" | tee -a "$API_SUMMARY_FILE"
      return 0
    fi
    auth_args+=(-H "${API_AUTH_HEADER}: ${API_AUTH_SCHEME} ${token}")
  fi

  auth_args+=(-H "Accept: application/json")
  if [[ -n "$body" ]]; then
    auth_args+=(-H "Content-Type: application/json" -d "$body")
  fi

  local raw response_body actual_code
  raw="$(curl "${auth_args[@]}" "$url" || true)"
  actual_code="$(printf '%s' "$raw" | tail -n1)"
  response_body="$(printf '%s' "$raw" | sed '$d')"

  local ok=1 detail=""
  if ! api__http_match "$expected" "$actual_code"; then
    ok=0
    detail="http expected=${expected} actual=${actual_code}"
  elif [[ -n "$oracle" ]]; then
    if ! printf '%s' "$response_body" | jq -e "$oracle" >/dev/null 2>&1; then
      ok=0
      detail="body oracle failed: ${oracle}"
    fi
  fi

  local req_json resp_json
  req_json="$(api__json_or_string "$body")"
  resp_json="$(api__json_or_string "$response_body")"

  if [[ "$ok" -eq 1 ]]; then
    API_PASSED=$((API_PASSED + 1))
    echo "PASS  ${branch_id} — ${name} (${actual_code})" | tee -a "$API_SUMMARY_FILE"
  else
    API_FAILED=$((API_FAILED + 1))
    echo "FAIL  ${branch_id} — ${name} — ${detail}" | tee -a "$API_SUMMARY_FILE"
  fi

  api__append_full_json "$(jq -cn \
    --arg event test \
    --arg branch_id "$branch_id" \
    --arg name "$name" \
    --arg role "$role" \
    --arg method "$method" \
    --arg endpoint "$path" \
    --arg expected_http "$expected" \
    --arg actual_code "$actual_code" \
    --arg body_oracle "$oracle" \
    --argjson request_body "$req_json" \
    --argjson response_body "$resp_json" \
    --argjson passed "$([[ "$ok" -eq 1 ]] && echo true || echo false)" \
    '{event:$event,branch_id:$branch_id,name:$name,role:$role,method:$method,endpoint:$endpoint,
      expected_http:$expected_http,actual_code:$actual_code,body_oracle:$body_oracle,
      request_body:$request_body,response_body:$response_body,passed:$passed}')"
}

api_run_get_case() {
  local branch_id="$1" name="$2" role="$3" path="$4" expected="$5"
  local oracle="${6:-}" skip_env="${7:-}"
  api_run_case "$branch_id" "$name" "$role" "GET" "$path" "" "$expected" "$oracle" "$skip_env"
}

api_runner_finalize_suite() {
  echo "]" >>"$API_FULL_FILE"
  {
    echo
    echo "passed=${API_PASSED} failed=${API_FAILED} skipped=${API_SKIPPED}"
    echo "finished=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "full_log=${API_FULL_FILE}"
  } | tee -a "$API_SUMMARY_FILE"

  if [[ "$API_FAILED" -gt 0 ]]; then
    return 1
  fi
  return 0
}
