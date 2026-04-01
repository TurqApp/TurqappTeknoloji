#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

source "scripts/test_suite_manifest.sh"

if [[ -f ".env.integration.local" ]]; then
  set -a
  source ".env.integration.local"
  set +a
fi

export INTEGRATION_AUTO_SEED="${INTEGRATION_AUTO_SEED:-1}"
export INTEGRATION_REQUIRE_SEED="${INTEGRATION_REQUIRE_SEED:-1}"

artifact_dir="${INTEGRATION_SMOKE_ARTIFACT_DIR:-artifacts/integration_smoke}"
smoke_manifest="${INTEGRATION_TEST_MANIFEST:-config/test_suites/integration_smoke.tsv}"

if [[ ! -f "$smoke_manifest" ]]; then
  echo "[integration-smoke] manifest not found: $smoke_manifest" >&2
  exit 1
fi

smoke_entries=()
while IFS= read -r smoke_entry; do
  smoke_entries+=("$smoke_entry")
done < <(load_suite_pairs "$smoke_manifest")

scenario_name_for_artifact() {
  local artifact="$1"
  basename "$artifact" .json
}

write_host_stub_artifact() {
  local artifact="$1"
  local scenario="$2"
  local test_status="$3"
  local export_reason="$4"

  mkdir -p "$(dirname "$artifact")"

  local failure_json='{}'
  if [[ "$test_status" -ne 0 ]]; then
    failure_json="$(node -e "process.stdout.write(JSON.stringify({message: 'smoke test exited with code ' + process.argv[1], source: 'host_stub'}))" "$test_status")"
  fi

  local artifact_status_json
  artifact_status_json="$(node -e "process.stdout.write(JSON.stringify({source: 'host_stub', exported: false, reason: process.argv[1] || 'artifact_unavailable'}))" "$export_reason")"

  cat >"$artifact" <<EOF
{
  "scenario": "$scenario",
  "probe": {
    "currentRoute": "",
    "previousRoute": ""
  },
  "telemetry": {
    "registered": false,
    "thresholdReport": {
      "issues": []
    }
  },
  "invariants": {
    "registered": false,
    "count": 0,
    "violations": []
  },
  "failure": $failure_json,
  "artifactStatus": $artifact_status_json
}
EOF
}

copy_suite_artifacts() {
  local suite_artifact_dir="$1"
  local artifact="$2"
  local scenario_name="$3"
  local runner_status="$4"

  local artifact_name
  artifact_name="$(basename "$artifact")"
  local screenshot_path="${artifact%.json}.png"
  local suite_screenshot_path="$suite_artifact_dir/$(basename "$screenshot_path")"
  local export_reason="scenario_artifact_missing"

  if [[ -f "$suite_artifact_dir/$artifact_name" ]]; then
    mkdir -p "$(dirname "$artifact")"
    cp "$suite_artifact_dir/$artifact_name" "$artifact"
    if [[ -f "$suite_screenshot_path" ]]; then
      cp "$suite_screenshot_path" "$screenshot_path"
    fi
    return 0
  fi

  if [[ "$runner_status" -eq 0 ]]; then
    export_reason="scenario_artifact_missing_after_success"
  fi
  write_host_stub_artifact "$artifact" "$scenario_name" "$runner_status" "$export_reason"
  return 1
}

artifact_is_host_stub() {
  local artifact="$1"
  [[ -f "$artifact" ]] || return 1
  rg -q '"source"[[:space:]]*:[[:space:]]*"host_stub"' "$artifact"
}

run_suite_entry() {
  local test_file="$1"
  local artifact="$2"
  local scenario_name="$3"
  local attempt=1
  local max_attempts=2

  while (( attempt <= max_attempts )); do
    local suite_manifest
    suite_manifest="$(mktemp /tmp/integration_smoke_suite.XXXXXX)"
    local suite_artifact_dir
    suite_artifact_dir="$(mktemp -d /tmp/integration_smoke_artifacts.XXXXXX)"
    local runner_status=0

    printf '%s\n' "$test_file" >"$suite_manifest"

    set +e
    INTEGRATION_TEST_MANIFEST="$suite_manifest" \
    INTEGRATION_SMOKE_ARTIFACT_DIR="$suite_artifact_dir" \
    bash scripts/run_turqapp_test_smoke.sh
    runner_status=$?
    set -e

    copy_suite_artifacts "$suite_artifact_dir" "$artifact" "$scenario_name" "$runner_status" || true

    rm -rf "$suite_artifact_dir"
    rm -f "$suite_manifest"

    if [[ "$runner_status" -eq 0 ]]; then
      return 0
    fi

    if (( attempt < max_attempts )) && artifact_is_host_stub "$artifact"; then
      echo "[integration-smoke] retrying $(basename "$test_file") after host stub failure"
      sleep 5
      attempt=$((attempt + 1))
      continue
    fi

    return "$runner_status"
  done

  return 1
}

rm -rf "$artifact_dir"
mkdir -p "$artifact_dir"

echo "[integration-smoke] manifest: $smoke_manifest"
echo "[integration-smoke] running ${#smoke_entries[@]} smoke tests"

smoke_status=0
smoke_artifacts=()
for entry in "${smoke_entries[@]}"; do
  IFS='|' read -r test_file artifact <<<"$entry"
  smoke_artifacts+=("$artifact")
  scenario_name="$(scenario_name_for_artifact "$artifact")"
  echo "[integration-smoke] running $(basename "$test_file")"
  if ! run_suite_entry "$test_file" "$artifact" "$scenario_name"; then
    smoke_status=1
  fi
done

existing_artifacts=0
for artifact in "${smoke_artifacts[@]}"; do
  if [[ -f "$artifact" ]]; then
    existing_artifacts=$((existing_artifacts + 1))
  fi
done

if [[ "$existing_artifacts" -gt 0 ]]; then
  echo "[integration-smoke] verifying artifact dumps ($existing_artifacts/${#smoke_artifacts[@]})"
  for artifact in "${smoke_artifacts[@]}"; do
    if [[ -f "$artifact" ]]; then
      echo "[integration-smoke] artifact ok: $artifact"
    else
      echo "[integration-smoke] missing artifact: $artifact" >&2
    fi
  done
  echo "[integration-smoke] exporting summary report"
  bash scripts/export_integration_smoke_report.sh
else
  echo "[integration-smoke] no artifact dumps exported; skipping summary report" >&2
fi

exit "$smoke_status"
