#!/usr/bin/env bash

set -euo pipefail

start_dir="${1:-$PWD}"

if [[ -d "$start_dir" ]]; then
  start_dir="$(cd "$start_dir" && pwd -P)"
else
  start_dir="$(pwd -P)"
fi

repo_keys=(
  "PUBNOON_ROOT"
  "COMP_TEMPLATE_ROOT"
  "NOLT_DIY_ROOT"
  "NOON2_FRONTEND_ROOT"
  "NOON2_CORE_ROOT"
)

# Pipe-separated candidate relative paths per repo, tried in order.
# Standalone checkouts win over nested ones inside noon2-activities.
repo_paths=(
  "pubnoon|noon2-activities/activities/pubnoon"
  "noon2-activity-competition-template|noon2-activities/activities/noon-competition-activity-racecars-v2"
  "nolt.diy"
  "noon2-frontend"
  "noon2_core"
)

repo_display_names=(
  "pubnoon"
  "noon2-activity-competition-template"
  "nolt.diy"
  "noon2-frontend"
  "noon2_core"
)

resolved_values=("" "" "" "" "")
candidate_roots=()

add_candidate() {
  local candidate="$1"
  local existing=""

  [[ -d "$candidate" ]] || return 0

  for existing in "${candidate_roots[@]:-}"; do
    [[ "$existing" == "$candidate" ]] && return 0
  done

  candidate_roots+=("$candidate")
}

current="$start_dir"
while true; do
  add_candidate "$current"
  add_candidate "$(dirname "$current")"

  parent="$(dirname "$current")"
  [[ "$parent" == "$current" ]] && break
  current="$parent"
done

if [[ -n "${NOON_WORK_ROOT:-}" ]]; then
  add_candidate "$NOON_WORK_ROOT"
fi

add_candidate "$HOME/work"
add_candidate "$HOME/dev"

for root in "${candidate_roots[@]}"; do
  for i in "${!repo_paths[@]}"; do
    [[ -n "${resolved_values[$i]}" ]] && continue

    IFS='|' read -r -a rel_paths <<< "${repo_paths[$i]}"
    for rel_path in "${rel_paths[@]}"; do
      repo_dir="$root/$rel_path"
      if [[ -d "$repo_dir" ]]; then
        resolved_values[$i]="$(cd "$repo_dir" && pwd -P)"
        break
      fi
    done
  done
done

missing=()
for i in "${!repo_paths[@]}"; do
  if [[ -n "${resolved_values[$i]}" ]]; then
    printf '%s=%q\n' "${repo_keys[$i]}" "${resolved_values[$i]}"
  else
    missing+=("${repo_display_names[$i]}")
  fi
done

if [[ "${#missing[@]}" -gt 0 ]]; then
  printf 'MISSING_REPOS=%q\n' "$(IFS=,; echo "${missing[*]}")"
else
  printf 'MISSING_REPOS=%q\n' ""
fi
