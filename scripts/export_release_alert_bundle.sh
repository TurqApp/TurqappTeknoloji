#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

smoke_report="${INTEGRATION_SMOKE_REPORT_OUTPUT:-artifacts/integration_smoke_report_latest.json}"
telemetry_report="${TELEMETRY_REPORT_OUTPUT:-artifacts/telemetry_threshold_report_latest.json}"
output_file="${RELEASE_ALERT_BUNDLE_OUTPUT:-artifacts/release_alert_bundle_latest.json}"

dart run tool/release_alert_bundle.dart \
  --output "$output_file" \
  --smoke-input "$smoke_report" \
  --telemetry-input "$telemetry_report"
