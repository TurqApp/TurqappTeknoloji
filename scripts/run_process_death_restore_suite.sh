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
android_adb_bin="${ANDROID_ADB_BIN:-/Users/turqapp/Library/Android/sdk/platform-tools/adb}"
android_original_stay_on=""
android_awake_watchdog_pid=""

suite_tests=()
while IFS= read -r suite_entry; do
  suite_tests+=("$suite_entry")
done < <(load_suite_entries "$MANIFEST")

seed_integration_fixture_if_enabled

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

android_prepare_awake_device() {
  [[ "${TARGET_PLATFORM}" == "android" ]] || return 0
  "$android_adb_bin" -s "$DEVICE_ID" shell svc power stayon true >/dev/null 2>&1 || true
  "$android_adb_bin" -s "$DEVICE_ID" shell input keyevent 224 >/dev/null 2>&1 || true
  "$android_adb_bin" -s "$DEVICE_ID" shell wm dismiss-keyguard >/dev/null 2>&1 || true
}

android_start_awake_watchdog() {
  [[ "${TARGET_PLATFORM}" == "android" ]] || return 0
  [[ -z "$android_awake_watchdog_pid" ]] || return 0

  (
    while true; do
      local_wakefulness="$("$android_adb_bin" -s "$DEVICE_ID" shell dumpsys power 2>/dev/null | tr -d '\r' | grep -m1 'mWakefulness=' | cut -d= -f2)"
      if [[ "$local_wakefulness" != "Awake" ]]; then
        "$android_adb_bin" -s "$DEVICE_ID" shell input keyevent 224 >/dev/null 2>&1 || true
        "$android_adb_bin" -s "$DEVICE_ID" shell wm dismiss-keyguard >/dev/null 2>&1 || true
      fi
      sleep 1
    done
  ) >/dev/null 2>&1 &
  android_awake_watchdog_pid="$!"
}

android_stop_awake_watchdog() {
  [[ -n "$android_awake_watchdog_pid" ]] || return 0
  kill "$android_awake_watchdog_pid" >/dev/null 2>&1 || true
  wait "$android_awake_watchdog_pid" 2>/dev/null || true
  android_awake_watchdog_pid=""
}

android_enable_keep_awake() {
  [[ "${TARGET_PLATFORM}" == "android" ]] || return 0

  if [[ -z "$android_original_stay_on" ]]; then
    android_original_stay_on="$("$android_adb_bin" -s "$DEVICE_ID" shell settings get global stay_on_while_plugged_in 2>/dev/null | tr -d '\r' | tr -d '\n')"
    if [[ -z "$android_original_stay_on" || "$android_original_stay_on" == "null" ]]; then
      android_original_stay_on="0"
    fi
  fi

  android_prepare_awake_device
}

android_restore_keep_awake() {
  [[ "${TARGET_PLATFORM}" == "android" ]] || return 0

  android_stop_awake_watchdog
  [[ -n "$android_original_stay_on" ]] || return 0

  "$android_adb_bin" -s "$DEVICE_ID" shell settings put global stay_on_while_plugged_in "$android_original_stay_on" >/dev/null 2>&1 || true
  "$android_adb_bin" -s "$DEVICE_ID" shell input keyevent 224 >/dev/null 2>&1 || true
  "$android_adb_bin" -s "$DEVICE_ID" shell wm dismiss-keyguard >/dev/null 2>&1 || true
}

trap 'android_restore_keep_awake; reset_integration_fixture_if_enabled' EXIT

pull_android_artifact() {
  local artifact="$1"
  local file_name
  file_name="$(basename "$artifact")"
  if ! "$android_adb_bin" -s "$DEVICE_ID" shell run-as "$android_package" test -f "$android_remote_artifact_dir/$file_name"; then
    return 1
  fi
  "$android_adb_bin" -s "$DEVICE_ID" exec-out run-as "$android_package" cat "$android_remote_artifact_dir/$file_name" > "$artifact"
  local screenshot_path="${artifact%.json}.png"
  if "$android_adb_bin" -s "$DEVICE_ID" shell run-as "$android_package" test -f "$android_remote_artifact_dir/$(basename "$screenshot_path")"; then
    "$android_adb_bin" -s "$DEVICE_ID" exec-out run-as "$android_package" cat "$android_remote_artifact_dir/$(basename "$screenshot_path")" > "$screenshot_path"
  fi
}

android_enable_keep_awake

android_prepare_awake_device
android_start_awake_watchdog
flutter "${COMMON_ARGS[@]}" "${suite_tests[0]}"
android_stop_awake_watchdog
if [[ "${TARGET_PLATFORM}" == "android" ]]; then
  prepare_artifact="${artifact_dir}/$(scenario_name_for_test "${suite_tests[0]}").json"
  pull_android_artifact "$prepare_artifact" || true
fi

if [[ "${TARGET_PLATFORM}" == "ios" ]]; then
  echo "[process-death-e2e] terminating iOS app"
  xcrun simctl terminate "${DEVICE_ID}" com.turqapp.app || true
else
  echo "[process-death-e2e] force-stopping Android app"
  "$android_adb_bin" -s "${DEVICE_ID}" shell am force-stop com.turqapp.app
fi

sleep 2

echo "[process-death-e2e] verify=$(basename "${suite_tests[1]}")"
android_prepare_awake_device
android_start_awake_watchdog
flutter "${COMMON_ARGS[@]}" "${suite_tests[1]}"
android_stop_awake_watchdog
if [[ "${TARGET_PLATFORM}" == "android" ]]; then
  verify_artifact="${artifact_dir}/$(scenario_name_for_test "${suite_tests[1]}").json"
  pull_android_artifact "$verify_artifact" || true
fi

echo "[process-death-e2e] restore flow passed"
