#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

input_file="${TELEMETRY_INPUT_FILE:-}"
output_file="${TELEMETRY_REPORT_OUTPUT:-artifacts/telemetry_threshold_report_latest.json}"
fail_on_blocking="${TELEMETRY_FAIL_ON_BLOCKING:-0}"

if [[ -z "$input_file" ]]; then
  echo "[telemetry-threshold-report] skipped (set TELEMETRY_INPUT_FILE to execute)"
  exit 0
fi

if [[ ! -f "$input_file" ]]; then
  echo "[telemetry-threshold-report] input file not found: $input_file" >&2
  exit 1
fi

dart run tool/telemetry_threshold_report.dart \
  --input "$input_file" \
  --output "$output_file" \
  --fail-on-blocking "$fail_on_blocking"
