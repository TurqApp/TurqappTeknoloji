#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ -f ".env.integration.local" ]]; then
  set -a
  source ".env.integration.local"
  set +a
fi

source "scripts/test_suite_manifest.sh"
source "scripts/integration_device_resolver.sh"
source "scripts/integration_seed_helper.sh"

: "${INTEGRATION_LOGIN_EMAIL:?set INTEGRATION_LOGIN_EMAIL}"
: "${INTEGRATION_LOGIN_PASSWORD:?set INTEGRATION_LOGIN_PASSWORD}"

TARGET_PLATFORM="${INTEGRATION_TARGET_PLATFORM:-android}"
DEVICE_ID="$(resolve_integration_device_id "${TARGET_PLATFORM}")"
MANIFEST="config/test_suites/process_death_e2e.txt"
artifact_dir="artifacts/integration_smoke"
android_package="${INTEGRATION_SMOKE_ANDROID_PACKAGE:-com.turqapp.app}"
android_remote_artifact_dir="${INTEGRATION_SMOKE_ANDROID_REMOTE_ARTIFACT_DIR:-files/integration_smoke}"

suite_tests=()
while IFS= read -r suite_entry; do
  suite_tests+=("$suite_entry")
done < <(load_suite_entries "$MANIFEST")

seed_integration_fixture_if_enabled
trap 'reset_integration_fixture_if_enabled' EXIT

if [[ "${#suite_tests[@]}" -ne 2 ]]; then
  echo "[process-death-e2e] expected exactly 2 suite entries" >&2
  exit 1
fi

COMMON_ARGS=(
  test
  --no-pub
  --dart-define=RUN_INTEGRATION_SMOKE=true
  --dart-define=INTEGRATION_DETERMINISTIC_STARTUP=true
  --dart-define=INTEGRATION_SUPPRESS_PERIODIC_SIDE_EFFECTS=true
  --dart-define=INTEGRATION_SKIP_BACKGROUND_STARTUP_WORK=true
  "--dart-define=INTEGRATION_LOGIN_EMAIL=${INTEGRATION_LOGIN_EMAIL}"
  "--dart-define=INTEGRATION_LOGIN_PASSWORD=${INTEGRATION_LOGIN_PASSWORD}"
  -d
  "${DEVICE_ID}"
)

echo "[process-death-e2e] platform=${TARGET_PLATFORM}"
echo "[process-death-e2e] device=${DEVICE_ID}"
echo "[process-death-e2e] prepare=$(basename "${suite_tests[0]}")"
mkdir -p "$artifact_dir"

scenario_name_for_test() {
  local test_file="$1"
  local name
  name="$(basename "$test_file" .dart)"
  printf '%s\n' "${name%_test}"
}

pull_android_artifact() {
  local artifact="$1"
  local file_name
  file_name="$(basename "$artifact")"
  if ! /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$DEVICE_ID" shell run-as "$android_package" test -f "$android_remote_artifact_dir/$file_name"; then
    return 1
  fi
  /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$DEVICE_ID" exec-out run-as "$android_package" cat "$android_remote_artifact_dir/$file_name" > "$artifact"
  local screenshot_path="${artifact%.json}.png"
  if /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$DEVICE_ID" shell run-as "$android_package" test -f "$android_remote_artifact_dir/$(basename "$screenshot_path")"; then
    /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$DEVICE_ID" exec-out run-as "$android_package" cat "$android_remote_artifact_dir/$(basename "$screenshot_path")" > "$screenshot_path"
  fi
}

flutter "${COMMON_ARGS[@]}" "${suite_tests[0]}"
if [[ "${TARGET_PLATFORM}" == "android" ]]; then
  prepare_artifact="${artifact_dir}/$(scenario_name_for_test "${suite_tests[0]}").json"
  pull_android_artifact "$prepare_artifact" || true
fi

if [[ "${TARGET_PLATFORM}" == "ios" ]]; then
  echo "[process-death-e2e] terminating iOS app"
  xcrun simctl terminate "${DEVICE_ID}" com.turqapp.app || true
else
  echo "[process-death-e2e] force-stopping Android app"
  /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "${DEVICE_ID}" shell am force-stop com.turqapp.app
fi

sleep 2

echo "[process-death-e2e] verify=$(basename "${suite_tests[1]}")"
flutter "${COMMON_ARGS[@]}" "${suite_tests[1]}"
if [[ "${TARGET_PLATFORM}" == "android" ]]; then
  verify_artifact="${artifact_dir}/$(scenario_name_for_test "${suite_tests[1]}").json"
  pull_android_artifact "$verify_artifact" || true
fi

echo "[process-death-e2e] restore flow passed"
