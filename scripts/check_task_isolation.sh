#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a git repository: $ROOT_DIR" >&2
  exit 1
fi

artifact_dir="${TASK_ISOLATION_ARTIFACT_DIR:-artifacts/task_isolation}"
expected_head=""
allow_csv=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --expected-head)
      expected_head="${2:-}"
      shift 2
      ;;
    --allow)
      allow_csv="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 64
      ;;
  esac
done

mkdir -p "$artifact_dir"

report_path="$artifact_dir/task_isolation_report.txt"
dirty_path="$artifact_dir/task_isolation_dirty_paths.txt"
allow_path="$artifact_dir/task_isolation_allowlist.txt"
unrelated_path="$artifact_dir/task_isolation_unrelated_paths.txt"

current_head="$(git rev-parse --short=8 HEAD)"
git status --porcelain=v1 >"$dirty_path"

printf '%s\n' "$allow_csv" | tr ',' '\n' | sed '/^[[:space:]]*$/d' >"$allow_path"

normalize_path() {
  local raw="$1"
  raw="${raw#"${ROOT_DIR}/"}"
  raw="${raw#./}"
  printf '%s' "$raw"
}

path_allowed() {
  local path="$1"
  if [[ ! -s "$allow_path" ]]; then
    return 1
  fi

  while IFS= read -r allowed; do
    [[ -n "$allowed" ]] || continue
    allowed="$(normalize_path "$allowed")"
    if [[ "$path" == "$allowed" || "$path" == "$allowed/"* ]]; then
      return 0
    fi
  done <"$allow_path"

  return 1
}

unrelated_count=0
>"$unrelated_path"
while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  file_path="$(normalize_path "${line#?? }")"
  if ! path_allowed "$file_path"; then
    printf '%s\n' "$line" >>"$unrelated_path"
    unrelated_count=$((unrelated_count + 1))
  fi
done <"$dirty_path"

head_drift="false"
if [[ -n "$expected_head" && "$expected_head" != "$current_head" ]]; then
  head_drift="true"
fi

dirty_total="$(wc -l <"$dirty_path" | tr -d ' ')"
allow_total="$(wc -l <"$allow_path" | tr -d ' ')"

{
  echo "Task isolation report generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "Repository root: $ROOT_DIR"
  echo "Current HEAD: $current_head"
  if [[ -n "$expected_head" ]]; then
    echo "Expected HEAD: $expected_head"
  fi
  echo "Dirty path count: $dirty_total"
  echo "Allowlist count: $allow_total"
  echo "Unrelated dirty count: $unrelated_count"
  echo "HEAD drift: $head_drift"
  echo
  echo "Allowlist:"
  if [[ -s "$allow_path" ]]; then
    sed 's/^/  - /' "$allow_path"
  else
    echo "  - (empty)"
  fi
  echo
  echo "Dirty paths:"
  if [[ -s "$dirty_path" ]]; then
    sed 's/^/  - /' "$dirty_path"
  else
    echo "  - (clean worktree)"
  fi
  echo
  echo "Unrelated dirty paths:"
  if [[ -s "$unrelated_path" ]]; then
    sed 's/^/  - /' "$unrelated_path"
  else
    echo "  - none"
  fi
} >"$report_path"

echo "Task isolation report generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Report path: $report_path"
echo "Dirty path inventory: $dirty_path"

if [[ "$head_drift" == "true" ]]; then
  echo
  echo "[FAIL] Task isolation guard detected HEAD drift."
  exit 2
fi

if [[ "$unrelated_count" -gt 0 ]]; then
  echo
  echo "[FAIL] Task isolation guard detected unrelated dirty files."
  exit 3
fi

echo
echo "[PASS] Task isolation guard passed."
