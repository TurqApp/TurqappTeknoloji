#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

adb_bin="${ANDROID_ADB_BIN:-/Users/turqapp/Library/Android/sdk/platform-tools/adb}"
device_id="${ANDROID_DEVICE_ID:-}"
package_name="${ANDROID_PACKAGE_NAME:-com.turqapp.app}"
line_count="${DEVICE_LOG_LINE_COUNT:-1500}"
raw_output="${DEVICE_LOG_RAW_OUTPUT:-artifacts/device_logs/android_logcat_latest.txt}"
report_output="${DEVICE_LOG_REPORT_OUTPUT:-artifacts/device_log_report_latest.json}"

if [[ -z "$device_id" ]]; then
  device_id="$("$adb_bin" devices | awk 'NR>1 && $2=="device" {print $1; exit}')"
fi

if [[ -z "$device_id" ]]; then
  echo "[device-log-report] skipped (no Android device detected)"
  exit 0
fi

mkdir -p "$(dirname "$raw_output")" "$(dirname "$report_output")"

process_id="$("$adb_bin" -s "$device_id" shell pidof "$package_name" | tr -d '\r')"

if [[ -n "$process_id" ]]; then
  "$adb_bin" -s "$device_id" logcat --pid="$process_id" -d -t "$line_count" > "$raw_output"
else
  "$adb_bin" -s "$device_id" logcat -d -t "$line_count" > "$raw_output"
fi

dart run tool/device_log_report.dart \
  --input "$raw_output" \
  --output "$report_output" \
  --device-id "$device_id" \
  --platform android \
  --package-name "$package_name" \
  --process-id "$process_id"

echo "[device-log-report] wrote raw log to $raw_output"
echo "[device-log-report] wrote report to $report_output"
