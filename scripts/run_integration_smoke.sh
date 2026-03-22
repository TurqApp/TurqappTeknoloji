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

artifact_dir="artifacts/integration_smoke"
android_package="${INTEGRATION_SMOKE_ANDROID_PACKAGE:-com.turqapp.app}"
android_remote_artifact_dir="${INTEGRATION_SMOKE_ANDROID_REMOTE_ARTIFACT_DIR:-files/integration_smoke}"
last_artifact_export_reason=""

default_fixture_file="integration_test/core/fixtures/smoke_fixture.device_baseline.json"
fixture_file="${INTEGRATION_FIXTURE_FILE:-}"
fixture_json="${INTEGRATION_FIXTURE_JSON:-}"
allow_stored_auth="${INTEGRATION_ALLOW_STORED_AUTH:-0}"
login_email="${INTEGRATION_LOGIN_EMAIL:-}"
login_password="${INTEGRATION_LOGIN_PASSWORD:-}"

if [[ -z "$fixture_file" && -f "$default_fixture_file" ]]; then
  fixture_file="$default_fixture_file"
fi

if [[ -n "$fixture_file" ]]; then
  if [[ ! -f "$fixture_file" ]]; then
    echo "[integration-smoke] fixture file not found: $fixture_file" >&2
    exit 1
  fi
  fixture_json="$(node -e "const fs=require('fs');const p=process.argv[1];const raw=JSON.parse(fs.readFileSync(p,'utf8'));process.stdout.write(JSON.stringify(raw));" "$fixture_file")"
fi

if [[ "$allow_stored_auth" != "1" ]]; then
  if [[ -z "$login_email" || -z "$login_password" ]]; then
    echo "[integration-smoke] auth credentials required" >&2
    echo "[integration-smoke] set INTEGRATION_LOGIN_EMAIL and INTEGRATION_LOGIN_PASSWORD" >&2
    echo "[integration-smoke] or set INTEGRATION_ALLOW_STORED_AUTH=1 for a best-effort local session run" >&2
    exit 2
  fi
fi

SMOKE_MANIFEST="config/test_suites/integration_smoke.tsv"
mapfile -t smoke_entries < <(load_suite_pairs "$SMOKE_MANIFEST")

declare -a flutter_args=(
  "test"
  "--no-pub"
  "--dart-define=RUN_INTEGRATION_SMOKE=true"
  "--dart-define=INTEGRATION_DETERMINISTIC_STARTUP=true"
  "--dart-define=INTEGRATION_SUPPRESS_PERIODIC_SIDE_EFFECTS=true"
  "--dart-define=INTEGRATION_SKIP_BACKGROUND_STARTUP_WORK=true"
)

if [[ -n "$login_email" && -n "$login_password" ]]; then
  flutter_args+=("--dart-define=INTEGRATION_LOGIN_EMAIL=$login_email")
  flutter_args+=("--dart-define=INTEGRATION_LOGIN_PASSWORD=$login_password")
fi

if [[ -n "$fixture_json" ]]; then
  flutter_args+=("--dart-define=INTEGRATION_FIXTURE_JSON=$fixture_json")
  echo "[integration-smoke] using fixture contract"
  if [[ -n "$fixture_file" ]]; then
    echo "[integration-smoke] fixture file: $fixture_file"
  fi
else
  echo "[integration-smoke] fixture contract not provided; continuity-only assertions active"
fi

rm -rf "$artifact_dir"
mkdir -p "$artifact_dir"

pick_android_device() {
  local android_devices=()
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    android_devices+=("$line")
  done < <(
    /Users/turqapp/Library/Android/sdk/platform-tools/adb devices |
      awk 'NR > 1 && $2 == "device" { print $1 }'
  )
  if [[ "${#android_devices[@]}" -eq 0 ]]; then
    return 0
  fi
  for candidate in "${android_devices[@]}"; do
    if [[ "$candidate" == *:* ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  printf '%s\n' "${android_devices[0]}"
}

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

device_id="${INTEGRATION_SMOKE_DEVICE_ID:-}"
if [[ -z "$device_id" ]]; then
  device_id="$(pick_android_device)"
fi
if [[ -n "$device_id" ]]; then
  flutter_args+=("-d" "$device_id")
  echo "[integration-smoke] target device: $device_id"
fi

echo "[integration-smoke] manifest: $SMOKE_MANIFEST"
echo "[integration-smoke] running ${#smoke_entries[@]} smoke tests"
smoke_status=0

is_android_package_installed() {
  local target_device="$1"
  /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$target_device" shell pm path "$android_package" >/dev/null 2>&1
}

pull_android_artifact() {
  local target_device="$1"
  local artifact="$2"
  last_artifact_export_reason=""
  if [[ -z "$target_device" || -z "$artifact" ]]; then
    echo "[integration-smoke] no Android device detected for artifact export" >&2
    last_artifact_export_reason="no_device"
    return 1
  fi
  if ! is_android_package_installed "$target_device"; then
    echo "[integration-smoke] package not installed at artifact export time: $android_package" >&2
    last_artifact_export_reason="package_not_installed"
    return 1
  fi
  local file_name
  file_name="$(basename "$artifact")"
  if ! /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$target_device" shell run-as "$android_package" test -f "$android_remote_artifact_dir/$file_name"; then
    echo "[integration-smoke] remote artifact missing: $file_name" >&2
    last_artifact_export_reason="remote_artifact_missing"
    return 1
  fi
  /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$target_device" exec-out run-as "$android_package" cat "$android_remote_artifact_dir/$file_name" > "$artifact"
  local screenshot_path="${artifact%.json}.png"
  if /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$target_device" shell run-as "$android_package" test -f "$android_remote_artifact_dir/$(basename "$screenshot_path")"; then
    /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$target_device" exec-out run-as "$android_package" cat "$android_remote_artifact_dir/$(basename "$screenshot_path")" > "$screenshot_path"
  fi
}

smoke_artifacts=()
for entry in "${smoke_entries[@]}"; do
  IFS='|' read -r test_file artifact <<<"$entry"
  smoke_artifacts+=("$artifact")
  scenario_name="$(scenario_name_for_artifact "$artifact")"
  echo "[integration-smoke] running $(basename "$test_file")"
  set +e
  flutter "${flutter_args[@]}" "$test_file"
  test_status=$?
  set -e
  if [[ "$test_status" -ne 0 ]]; then
    smoke_status=1
  fi
  if [[ -n "$device_id" ]]; then
    echo "[integration-smoke] pulling Android artifact for $(basename "$test_file")"
    if ! pull_android_artifact "$device_id" "$artifact"; then
      echo "[integration-smoke] artifact export skipped for $(basename "$artifact")" >&2
      write_host_stub_artifact "$artifact" "$scenario_name" "$test_status" "$last_artifact_export_reason"
    fi
  elif [[ ! -f "$artifact" ]]; then
    write_host_stub_artifact "$artifact" "$scenario_name" "$test_status" "no_device"
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
