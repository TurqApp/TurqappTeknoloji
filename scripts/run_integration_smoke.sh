#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

artifact_dir="artifacts/integration_smoke"
android_package="${INTEGRATION_SMOKE_ANDROID_PACKAGE:-com.turqapp.app}"
android_remote_artifact_dir="${INTEGRATION_SMOKE_ANDROID_REMOTE_ARTIFACT_DIR:-files/integration_smoke}"

default_fixture_file="integration_test/fixtures/smoke_fixture.device_baseline.json"
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

declare -a smoke_tests=(
  "integration_test/feed_resume_test.dart"
  "integration_test/explore_preview_gate_test.dart"
  "integration_test/profile_resume_test.dart"
  "integration_test/short_refresh_preserve_test.dart"
  "integration_test/notifications_snapshot_mutation_test.dart"
)

declare -a smoke_artifacts=(
  "$artifact_dir/feed_resume.json"
  "$artifact_dir/explore_preview_gate.json"
  "$artifact_dir/profile_resume.json"
  "$artifact_dir/short_refresh_preserve.json"
  "$artifact_dir/notifications_snapshot_mutation.json"
)

declare -a flutter_args=(
  "test"
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

device_id="${INTEGRATION_SMOKE_DEVICE_ID:-}"
if [[ -z "$device_id" ]]; then
  device_id="$(pick_android_device)"
fi
if [[ -n "$device_id" ]]; then
  flutter_args+=("-d" "$device_id")
  echo "[integration-smoke] target device: $device_id"
fi

echo "[integration-smoke] running ${#smoke_tests[@]} smoke tests"
set +e
flutter "${flutter_args[@]}" "${smoke_tests[@]}"
smoke_status=$?
set -e

pull_android_artifacts() {
  local target_device="$1"
  if [[ -z "$target_device" ]]; then
    echo "[integration-smoke] no Android device detected for artifact export" >&2
    return 1
  fi
  for artifact in "${smoke_artifacts[@]}"; do
    local file_name
    file_name="$(basename "$artifact")"
    if ! /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$target_device" shell run-as "$android_package" test -f "$android_remote_artifact_dir/$file_name"; then
      echo "[integration-smoke] remote artifact missing: $file_name" >&2
      return 1
    fi
    /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$target_device" exec-out run-as "$android_package" cat "$android_remote_artifact_dir/$file_name" > "$artifact"
    local screenshot_path="${artifact%.json}.png"
    if /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$target_device" shell run-as "$android_package" test -f "$android_remote_artifact_dir/$(basename "$screenshot_path")"; then
      /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$target_device" exec-out run-as "$android_package" cat "$android_remote_artifact_dir/$(basename "$screenshot_path")" > "$screenshot_path"
    fi
  done
}

if [[ -n "$device_id" ]]; then
  echo "[integration-smoke] pulling Android artifacts from $device_id"
  pull_android_artifacts "$device_id"
fi

echo "[integration-smoke] verifying ${#smoke_artifacts[@]} artifact dumps"
for artifact in "${smoke_artifacts[@]}"; do
  if [[ ! -f "$artifact" ]]; then
    echo "[integration-smoke] missing artifact: $artifact" >&2
    exit 1
  fi
  echo "[integration-smoke] artifact ok: $artifact"
done

echo "[integration-smoke] exporting summary report"
bash scripts/export_integration_smoke_report.sh

exit "$smoke_status"
