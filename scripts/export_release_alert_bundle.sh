#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

smoke_report="${INTEGRATION_SMOKE_REPORT_OUTPUT:-artifacts/integration_smoke_report_latest.json}"
telemetry_report="${TELEMETRY_REPORT_OUTPUT:-artifacts/telemetry_threshold_report_latest.json}"
output_file="${RELEASE_ALERT_BUNDLE_OUTPUT:-artifacts/release_alert_bundle_latest.json}"
allow_stale_telemetry="${RELEASE_ALERT_ALLOW_STALE_TELEMETRY:-0}"

telemetry_input=""
if [[ -f "$telemetry_report" ]]; then
  if [[ "$allow_stale_telemetry" == "1" || ! -f "$smoke_report" || "$telemetry_report" -nt "$smoke_report" ]]; then
    telemetry_input="$telemetry_report"
  else
    echo "[release-alert-bundle] telemetry report older than smoke report; skipping stale telemetry input"
  fi
fi

dart run tool/release_alert_bundle.dart \
  --output "$output_file" \
  --smoke-input "$smoke_report" \
  --telemetry-input "$telemetry_input"
