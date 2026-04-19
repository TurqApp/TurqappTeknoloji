#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

source "scripts/test_suite_manifest.sh"
source "scripts/integration_device_resolver.sh"
source "scripts/integration_seed_helper.sh"

if [[ -f ".env.integration.local" ]]; then
  set -a
  source ".env.integration.local"
  set +a
fi

export INTEGRATION_AUTO_SEED="${INTEGRATION_AUTO_SEED:-1}"
export INTEGRATION_REQUIRE_SEED="${INTEGRATION_REQUIRE_SEED:-1}"

: "${INTEGRATION_LOGIN_EMAIL:?set INTEGRATION_LOGIN_EMAIL}"
: "${INTEGRATION_LOGIN_PASSWORD:?set INTEGRATION_LOGIN_PASSWORD}"

TARGET_PLATFORM="${INTEGRATION_TARGET_PLATFORM:-android}"
DEVICE_ID="$(resolve_integration_device_id "${TARGET_PLATFORM}")"
MANIFEST="${INTEGRATION_TEST_MANIFEST:-config/test_suites/release_gate_e2e.txt}"
ARTIFACT_DIR="${INTEGRATION_SMOKE_ARTIFACT_DIR:-artifacts/integration_smoke}"
ANDROID_ADB_BIN="${ANDROID_ADB_BIN:-/Users/turqapp/Library/Android/sdk/platform-tools/adb}"
ANDROID_PACKAGE="${INTEGRATION_SMOKE_ANDROID_PACKAGE:-com.turqapp.app}"
ANDROID_REMOTE_ARTIFACT_DIR="${INTEGRATION_SMOKE_ANDROID_REMOTE_ARTIFACT_DIR:-files/integration_smoke}"
ANDROID_EXPORT_POLL_SECONDS="${INTEGRATION_SMOKE_ANDROID_EXPORT_POLL_SECONDS:-0.25}"
ANDROID_CLEAR_APP_DATA_BETWEEN_SUITES="${INTEGRATION_SMOKE_CLEAR_APP_DATA_BETWEEN_SUITES:-1}"
ANDROID_PACKAGE_SYNC_RETRY_COUNT="${INTEGRATION_SMOKE_ANDROID_PACKAGE_SYNC_RETRY_COUNT:-12}"
ANDROID_PACKAGE_SYNC_RETRY_SLEEP_SECONDS="${INTEGRATION_SMOKE_ANDROID_PACKAGE_SYNC_RETRY_SLEEP_SECONDS:-0.5}"
ANDROID_LOGCAT_FORMAT="${INTEGRATION_SMOKE_ANDROID_LOGCAT_FORMAT:-threadtime}"
INTEGRATION_SUITE_RETRY_COUNT="${INTEGRATION_SMOKE_SUITE_RETRY_COUNT:-2}"
INTEGRATION_SUITE_IDLE_TIMEOUT_SECONDS="${INTEGRATION_SMOKE_SUITE_IDLE_TIMEOUT_SECONDS:-45}"
android_original_stay_on=""
android_awake_watchdog_pid=""
last_device_log_reason=""
last_device_log_raw_path=""
last_device_log_report_path=""
last_suite_runner_reason=""
default_fixture_file="integration_test/core/fixtures/smoke_fixture.device_baseline.json"
fixture_file="${INTEGRATION_FIXTURE_FILE:-}"
fixture_json="${INTEGRATION_FIXTURE_JSON:-}"

if [[ ! -f "$MANIFEST" ]]; then
  echo "[turqapp-test] manifest not found: $MANIFEST" >&2
  exit 1
fi

if [[ -z "$fixture_file" && -f "$default_fixture_file" ]]; then
  fixture_file="$default_fixture_file"
fi

if [[ -n "$fixture_file" ]]; then
  if [[ ! -f "$fixture_file" ]]; then
    echo "[turqapp-test] fixture file not found: $fixture_file" >&2
    exit 1
  fi
  fixture_json="$(node -e "const fs=require('fs');const p=process.argv[1];const raw=JSON.parse(fs.readFileSync(p,'utf8'));process.stdout.write(JSON.stringify(raw));" "$fixture_file")"
fi

rm -rf "$ARTIFACT_DIR"
mkdir -p "$ARTIFACT_DIR"

write_host_stub_artifact() {
  local scenario="$1"
  local test_status="$2"
  local export_reason="${3:-artifact_unavailable}"
  local output_file="$ARTIFACT_DIR/${scenario}.json"

  local failure_json='{}'
  if [[ "$test_status" -ne 0 ]]; then
    failure_json="$(node -e "process.stdout.write(JSON.stringify({message: 'smoke test exited with code ' + process.argv[1], source: 'host_stub'}))" "$test_status")"
  fi

  cat >"$output_file" <<EOF
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
  "artifactStatus": {
    "source": "host_stub",
    "exported": false,
    "reason": "$export_reason"
  }
}
EOF
}

annotate_device_export_artifact() {
  local artifact_file="$1"
  local screenshot_path="${2:-}"

  node -e "
const fs = require('fs');
const artifactPath = process.argv[1];
const screenshotPath = process.argv[2];
const raw = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
raw.artifactStatus = {
  source: 'android_device_export',
  exported: true,
  reason: '',
};
if (screenshotPath) {
  raw.failure = raw.failure && typeof raw.failure === 'object' ? raw.failure : {};
  raw.failure.screenshotPath = screenshotPath;
}
fs.writeFileSync(artifactPath, JSON.stringify(raw, null, 2));
" "$artifact_file" "$screenshot_path"
}

annotate_artifact_with_device_log() {
  local artifact_file="$1"
  local report_file="${2:-}"
  local raw_file="${3:-}"
  local export_reason="${4:-}"

  [[ -f "$artifact_file" ]] || return 0

  node -e "
const fs = require('fs');
const artifactPath = process.argv[1];
const reportPath = process.argv[2];
const rawPath = process.argv[3];
const exportReason = process.argv[4];
const raw = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
const reportExists = reportPath && fs.existsSync(reportPath);
const rawExists = rawPath && fs.existsSync(rawPath);
raw.deviceLog = reportExists
  ? JSON.parse(fs.readFileSync(reportPath, 'utf8'))
  : {};
raw.deviceLogArtifacts = {
  source: 'android_logcat',
  exported: reportExists,
  reason: exportReason || (reportExists ? '' : 'device_log_unavailable'),
  rawPath: rawExists ? rawPath : '',
  reportPath: reportExists ? reportPath : '',
};
fs.writeFileSync(artifactPath, JSON.stringify(raw, null, 2));
" "$artifact_file" "$report_file" "$raw_file" "$export_reason"
}

materialize_scenario_artifact_alias() {
  local scenario_name="$1"
  local exact_json="$ARTIFACT_DIR/${scenario_name}.json"
  if [[ -f "$exact_json" ]]; then
    return 0
  fi

  local normalized_name="${scenario_name%_test}"
  if [[ "$normalized_name" == "$scenario_name" ]]; then
    return 1
  fi

  local source_json="$ARTIFACT_DIR/${normalized_name}.json"
  if [[ ! -f "$source_json" ]]; then
    return 1
  fi

  cp "$source_json" "$exact_json"

  local source_png="$ARTIFACT_DIR/${normalized_name}.png"
  local exact_png="$ARTIFACT_DIR/${scenario_name}.png"
  if [[ -f "$source_png" && ! -f "$exact_png" ]]; then
    cp "$source_png" "$exact_png"
  fi

  return 0
}

is_valid_json_file() {
  local json_file="$1"
  node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" "$json_file" >/dev/null 2>&1
}

suite_tests=()
if [[ "$MANIFEST" == *.tsv ]]; then
  while IFS= read -r suite_entry; do
    IFS='|' read -r test_file _ <<<"$suite_entry"
    suite_tests+=("$test_file")
  done < <(load_suite_pairs "$MANIFEST")
else
  while IFS= read -r suite_entry; do
    suite_tests+=("$suite_entry")
  done < <(load_suite_entries "$MANIFEST")
fi

seed_integration_fixture_if_enabled

android_prepare_awake_device() {
  [[ "${TARGET_PLATFORM}" == "android" ]] || return 0
  "$ANDROID_ADB_BIN" -s "$DEVICE_ID" shell svc power stayon true >/dev/null 2>&1 || true
  "$ANDROID_ADB_BIN" -s "$DEVICE_ID" shell input keyevent 224 >/dev/null 2>&1 || true
  "$ANDROID_ADB_BIN" -s "$DEVICE_ID" shell wm dismiss-keyguard >/dev/null 2>&1 || true
}

android_start_awake_watchdog() {
  [[ "${TARGET_PLATFORM}" == "android" ]] || return 0
  [[ -n "$DEVICE_ID" ]] || return 0
  [[ -z "$android_awake_watchdog_pid" ]] || return 0
  (
    while true; do
      local_wakefulness="$("$ANDROID_ADB_BIN" -s "$DEVICE_ID" shell dumpsys power 2>/dev/null | tr -d '\r' | grep -m1 'mWakefulness=' | cut -d= -f2)"
      if [[ "$local_wakefulness" != "Awake" ]]; then
        "$ANDROID_ADB_BIN" -s "$DEVICE_ID" shell input keyevent 224 >/dev/null 2>&1 || true
        "$ANDROID_ADB_BIN" -s "$DEVICE_ID" shell wm dismiss-keyguard >/dev/null 2>&1 || true
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
    android_original_stay_on="$("$ANDROID_ADB_BIN" -s "$DEVICE_ID" shell settings get global stay_on_while_plugged_in 2>/dev/null | tr -d '\r' | tr -d '\n')"
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
  "$ANDROID_ADB_BIN" -s "$DEVICE_ID" shell settings put global stay_on_while_plugged_in "$android_original_stay_on" >/dev/null 2>&1 || true
  "$ANDROID_ADB_BIN" -s "$DEVICE_ID" shell input keyevent 224 >/dev/null 2>&1 || true
  "$ANDROID_ADB_BIN" -s "$DEVICE_ID" shell wm dismiss-keyguard >/dev/null 2>&1 || true
}

trap 'android_restore_keep_awake; reset_integration_fixture_if_enabled' EXIT

last_artifact_export_reason=""

COMMON_ARGS=(
  test
  --no-pub
  --reporter=expanded
  --dart-define=RUN_INTEGRATION_SMOKE=true
  --dart-define=INTEGRATION_DETERMINISTIC_STARTUP=true
  --dart-define=INTEGRATION_SUPPRESS_PERIODIC_SIDE_EFFECTS=true
  --dart-define=INTEGRATION_SKIP_BACKGROUND_STARTUP_WORK=true
  "--dart-define=INTEGRATION_LOGIN_EMAIL=${INTEGRATION_LOGIN_EMAIL}"
  "--dart-define=INTEGRATION_LOGIN_PASSWORD=${INTEGRATION_LOGIN_PASSWORD}"
  -d
  "${DEVICE_ID}"
)

if [[ -n "$fixture_json" ]]; then
  COMMON_ARGS+=("--dart-define=INTEGRATION_FIXTURE_JSON=${fixture_json}")
fi

if [[ -n "${INTEGRATION_EXTRA_DART_DEFINES:-}" ]]; then
  while IFS= read -r extra_define; do
    [[ -n "$extra_define" ]] || continue
    COMMON_ARGS+=("--dart-define=${extra_define}")
  done < <(printf '%s\n' "${INTEGRATION_EXTRA_DART_DEFINES}" | tr ',' '\n')
fi

echo "[turqapp-test] platform=${TARGET_PLATFORM}"
echo "[turqapp-test] device=${DEVICE_ID}"
echo "[turqapp-test] manifest=${MANIFEST} count=${#suite_tests[@]}"
if [[ -n "$fixture_file" ]]; then
  echo "[turqapp-test] fixture=${fixture_file}"
fi

is_android_package_installed() {
  local target_device="$1"
  "$ANDROID_ADB_BIN" -s "$target_device" \
    shell pm path "$ANDROID_PACKAGE" >/dev/null 2>&1
}

wait_for_android_package_install() {
  local target_device="$1"
  local retry_count="$ANDROID_PACKAGE_SYNC_RETRY_COUNT"
  local retry_sleep="$ANDROID_PACKAGE_SYNC_RETRY_SLEEP_SECONDS"

  if [[ -z "$target_device" ]]; then
    return 1
  fi

  if is_android_package_installed "$target_device"; then
    return 0
  fi

  local attempt=0
  while [[ "$attempt" -lt "$retry_count" ]]; do
    sleep "$retry_sleep"
    if is_android_package_installed "$target_device"; then
      return 0
    fi
    attempt=$((attempt + 1))
  done

  return 1
}

should_retry_host_stub_reason() {
  local reason="${1:-}"
  case "$reason" in
    package_not_installed|remote_artifact_missing|remote_artifact_copy_failed|scenario_artifact_missing|suite_idle_timeout|suite_missing_status|suite_empty_status)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

run_flutter_suite_with_watchdog() {
  local test_file="$1"
  local scenario_name="$2"
  local suite_log="$ARTIFACT_DIR/${scenario_name}.suite_stdout.log"
  local status_file="$ARTIFACT_DIR/${scenario_name}.suite_status"
  local idle_timeout="$INTEGRATION_SUITE_IDLE_TIMEOUT_SECONDS"
  local runner_pid=""
  local printed_bytes=0
  local current_size=0
  local last_output_epoch
  local now_epoch

  last_suite_runner_reason=""
  rm -f "$suite_log" "$status_file"

  (
    if flutter "${COMMON_ARGS[@]}" "$test_file" >"$suite_log" 2>&1; then
      printf '0' >"$status_file"
    else
      printf '%s' "$?" >"$status_file"
    fi
  ) &
  runner_pid="$!"
  last_output_epoch="$(date +%s)"

  while kill -0 "$runner_pid" >/dev/null 2>&1; do
    current_size="$(wc -c <"$suite_log" 2>/dev/null || printf '0')"
    if [[ "$current_size" -gt "$printed_bytes" ]]; then
      tail -c "+$((printed_bytes + 1))" "$suite_log"
      printed_bytes="$current_size"
      last_output_epoch="$(date +%s)"
    fi

    if [[ "$idle_timeout" -gt 0 ]]; then
      now_epoch="$(date +%s)"
      if (( now_epoch - last_output_epoch >= idle_timeout )); then
        echo "[turqapp-test] suite idle timeout scenario=${scenario_name} idleSeconds=${idle_timeout}"
        kill "$runner_pid" >/dev/null 2>&1 || true
        sleep 2
        kill -9 "$runner_pid" >/dev/null 2>&1 || true
        wait "$runner_pid" 2>/dev/null || true
        current_size="$(wc -c <"$suite_log" 2>/dev/null || printf '0')"
        if [[ "$current_size" -gt "$printed_bytes" ]]; then
          tail -c "+$((printed_bytes + 1))" "$suite_log"
        fi
        printf '124' >"$status_file"
        last_suite_runner_reason="suite_idle_timeout"
        return 124
      fi
    fi

    sleep 1
  done

  wait "$runner_pid" 2>/dev/null || true

  current_size="$(wc -c <"$suite_log" 2>/dev/null || printf '0')"
  if [[ "$current_size" -gt "$printed_bytes" ]]; then
    tail -c "+$((printed_bytes + 1))" "$suite_log"
  fi

  if [[ ! -f "$status_file" ]]; then
    last_suite_runner_reason="suite_missing_status"
    return 1
  fi

  local status_text
  status_text="$(tr -d '\r\n[:space:]' <"$status_file")"
  rm -f "$status_file"
  if [[ -z "$status_text" ]]; then
    last_suite_runner_reason="suite_empty_status"
    return 1
  fi

  if [[ "$status_text" == "0" ]]; then
    last_suite_runner_reason=""
    return 0
  fi

  last_suite_runner_reason="suite_exit_${status_text}"
  return "$status_text"
}

sync_android_remote_artifacts() {
  local target_device="$1"
  last_artifact_export_reason=""

  if [[ -z "$target_device" ]]; then
    last_artifact_export_reason="no_device"
    return 1
  fi
  if ! wait_for_android_package_install "$target_device"; then
    last_artifact_export_reason="package_not_installed"
    return 1
  fi

  local remote_names=()
  while IFS= read -r remote_name; do
    [[ -n "$remote_name" ]] || continue
    remote_names+=("$remote_name")
  done < <(
    "$ANDROID_ADB_BIN" -s "$target_device" \
      shell run-as "$ANDROID_PACKAGE" ls "$ANDROID_REMOTE_ARTIFACT_DIR" 2>/dev/null |
      tr -d '\r' |
      grep -E '\.(json|png)$' || true
  )

  if [[ "${#remote_names[@]}" -eq 0 ]]; then
    last_artifact_export_reason="remote_artifact_missing"
    return 1
  fi

  local pulled_any=0
  local pulled_jsons=()
  for remote_name in "${remote_names[@]}"; do
    local local_artifact="$ARTIFACT_DIR/$remote_name"
    local tmp_artifact="${local_artifact}.tmp"
    if "$ANDROID_ADB_BIN" -s "$target_device" \
      exec-out run-as "$ANDROID_PACKAGE" cat "$ANDROID_REMOTE_ARTIFACT_DIR/$remote_name" >"$tmp_artifact"; then
      if [[ "$remote_name" == *.json ]] && ! is_valid_json_file "$tmp_artifact"; then
        rm -f "$tmp_artifact"
        continue
      fi
      mv "$tmp_artifact" "$local_artifact"
      pulled_any=1
      if [[ "$local_artifact" == *.json ]]; then
        pulled_jsons+=("$local_artifact")
      fi
    else
      rm -f "$tmp_artifact"
    fi
  done

  if [[ "$pulled_any" -ne 1 ]]; then
    last_artifact_export_reason="remote_artifact_copy_failed"
    return 1
  fi

  for json_artifact in "${pulled_jsons[@]}"; do
    local screenshot_path=""
    local local_screenshot="${json_artifact%.json}.png"
    if [[ -f "$local_screenshot" ]]; then
      screenshot_path="$local_screenshot"
    fi
    annotate_device_export_artifact "$json_artifact" "$screenshot_path"
  done

  return 0
}

start_android_artifact_mirror() {
  local target_device="$1"
  local scenario_name="$2"
  local stop_file="$ARTIFACT_DIR/.${scenario_name}.mirror.stop"
  rm -f "$stop_file"
  (
    while [[ ! -f "$stop_file" ]]; do
      sync_android_remote_artifacts "$target_device" >/dev/null 2>&1 || true
      sleep "$ANDROID_EXPORT_POLL_SECONDS"
    done
  ) >/dev/null 2>&1 &
  printf '%s|%s\n' "$!" "$stop_file"
}

stop_android_artifact_mirror() {
  local handle="$1"
  [[ -n "$handle" ]] || return 0
  local watcher_pid="${handle%%|*}"
  local stop_file="${handle#*|}"
  : >"$stop_file"
  wait "$watcher_pid" 2>/dev/null || true
  rm -f "$stop_file"
}

reset_android_suite_state() {
  [[ "$TARGET_PLATFORM" == "android" ]] || return 0
  [[ -n "$DEVICE_ID" ]] || return 0
  if is_android_package_installed "$DEVICE_ID"; then
    "$ANDROID_ADB_BIN" -s "$DEVICE_ID" \
      shell am force-stop "$ANDROID_PACKAGE" >/dev/null 2>&1 || true
    if [[ "$ANDROID_CLEAR_APP_DATA_BETWEEN_SUITES" == "1" ]]; then
      "$ANDROID_ADB_BIN" -s "$DEVICE_ID" \
        shell pm clear "$ANDROID_PACKAGE" >/dev/null 2>&1 || true
      sleep 1
    fi
    "$ANDROID_ADB_BIN" -s "$DEVICE_ID" \
      shell run-as "$ANDROID_PACKAGE" rm -rf "$ANDROID_REMOTE_ARTIFACT_DIR" >/dev/null 2>&1 || true
    "$ANDROID_ADB_BIN" -s "$DEVICE_ID" \
      shell run-as "$ANDROID_PACKAGE" mkdir -p "$ANDROID_REMOTE_ARTIFACT_DIR" >/dev/null 2>&1 || true
    sleep 1
  fi
}

reset_android_suite_device_log_buffer() {
  [[ "$TARGET_PLATFORM" == "android" ]] || return 0
  [[ -n "$DEVICE_ID" ]] || return 0
  "$ANDROID_ADB_BIN" -s "$DEVICE_ID" logcat -c >/dev/null 2>&1 || true
}

export_android_suite_device_log() {
  local target_device="$1"
  local scenario_name="$2"
  last_device_log_reason=""
  last_device_log_raw_path=""
  last_device_log_report_path=""

  if [[ "$TARGET_PLATFORM" != "android" ]]; then
    last_device_log_reason="not_applicable"
    return 1
  fi
  if [[ -z "$target_device" ]]; then
    last_device_log_reason="no_device"
    return 1
  fi

  local raw_output="$ARTIFACT_DIR/${scenario_name}.device_logcat.txt"
  local report_output="$ARTIFACT_DIR/${scenario_name}.device_log_report.json"
  local process_id
  process_id="$("$ANDROID_ADB_BIN" -s "$target_device" shell pidof "$ANDROID_PACKAGE" 2>/dev/null | tr -d '\r' | tr -d '\n')"

  if ! "$ANDROID_ADB_BIN" -s "$target_device" \
    logcat -d -v "$ANDROID_LOGCAT_FORMAT" >"$raw_output"; then
    rm -f "$raw_output"
    last_device_log_reason="logcat_dump_failed"
    return 1
  fi

  last_device_log_raw_path="$raw_output"

  if ! dart run tool/device_log_report.dart \
    --input "$raw_output" \
    --output "$report_output" \
    --device-id "$target_device" \
    --platform android \
    --package-name "$ANDROID_PACKAGE" \
    --process-id "$process_id" >/dev/null; then
    rm -f "$report_output"
    last_device_log_reason="report_build_failed"
    return 1
  fi

  last_device_log_report_path="$report_output"
  return 0
}

if [[ "$TARGET_PLATFORM" == "android" && -n "$DEVICE_ID" ]]; then
  android_enable_keep_awake
  reset_android_suite_state
fi

for test_file in "${suite_tests[@]}"; do
  echo "[turqapp-test] suite=$(basename "$test_file" .dart)"
  scenario_name="$(basename "$test_file" .dart)"
  suite_attempt=1
  final_test_status=1
  while true; do
    watcher_handle=""
    rm -f \
      "$ARTIFACT_DIR/${scenario_name}.json" \
      "$ARTIFACT_DIR/${scenario_name}.png" \
      "$ARTIFACT_DIR/${scenario_name}_test.json" \
      "$ARTIFACT_DIR/${scenario_name}_test.png"
    if [[ "$TARGET_PLATFORM" == "android" && -n "$DEVICE_ID" ]]; then
      reset_android_suite_state
      android_prepare_awake_device
      reset_android_suite_device_log_buffer
      android_start_awake_watchdog
      watcher_handle="$(start_android_artifact_mirror "$DEVICE_ID" "$scenario_name")"
    fi
    test_status=0
    if run_flutter_suite_with_watchdog "$test_file" "$scenario_name"; then
      test_status=0
    else
      test_status=$?
    fi
    if [[ -n "$watcher_handle" ]]; then
      stop_android_artifact_mirror "$watcher_handle"
    fi
    if [[ "$TARGET_PLATFORM" == "android" && -n "$DEVICE_ID" ]]; then
      android_stop_awake_watchdog
      export_android_suite_device_log "$DEVICE_ID" "$scenario_name" >/dev/null 2>&1 || true
      sync_android_remote_artifacts "$DEVICE_ID" >/dev/null 2>&1 || true
    fi
    materialize_scenario_artifact_alias "$scenario_name" || true
    if [[ "$test_status" -ne 0 ]] && [[ ! -f "$ARTIFACT_DIR/${scenario_name}.json" ]]; then
      case "${last_suite_runner_reason:-}" in
        suite_idle_timeout|suite_missing_status|suite_empty_status)
          last_artifact_export_reason="$last_suite_runner_reason"
          ;;
      esac
    fi
    if [[ ! -f "$ARTIFACT_DIR/${scenario_name}.json" ]]; then
      write_host_stub_artifact \
        "$scenario_name" \
        "$test_status" \
        "${last_artifact_export_reason:-scenario_artifact_missing}"
    fi
    annotate_artifact_with_device_log \
      "$ARTIFACT_DIR/${scenario_name}.json" \
      "${last_device_log_report_path:-}" \
      "${last_device_log_raw_path:-}" \
      "${last_device_log_reason:-}" || true

    final_test_status="$test_status"
    if [[ "$test_status" -eq 0 ]]; then
      break
    fi

    if [[ "$suite_attempt" -ge "$INTEGRATION_SUITE_RETRY_COUNT" ]] || \
      ! should_retry_host_stub_reason "${last_artifact_export_reason:-}"; then
      break
    fi

    echo "[turqapp-test] retrying suite=${scenario_name} attempt=$((suite_attempt + 1)) reason=${last_artifact_export_reason:-unknown}"
    suite_attempt=$((suite_attempt + 1))
  done
  if [[ "$final_test_status" -ne 0 ]]; then
    if [[ -d "$ARTIFACT_DIR" ]]; then
      echo "[turqapp-test] failure artifacts:"
      find "$ARTIFACT_DIR" -maxdepth 1 -type f \
        \( -name '*.json' -o -name '*.png' \) -print | sort
      while IFS= read -r artifact_json; do
        echo "[turqapp-test] artifact_json=${artifact_json}"
        sed -n '1,220p' "$artifact_json"
      done < <(find "$ARTIFACT_DIR" -maxdepth 1 -type f -name '*.json' | sort)
    fi
    exit 1
  fi
done

echo "[turqapp-test] all suites passed"
