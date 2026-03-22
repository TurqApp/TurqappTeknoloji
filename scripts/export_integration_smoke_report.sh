#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

input_dir="${INTEGRATION_SMOKE_ARTIFACT_DIR:-artifacts/integration_smoke}"
output_file="${INTEGRATION_SMOKE_REPORT_OUTPUT:-artifacts/integration_smoke_report_latest.json}"
fail_on_blocking="${INTEGRATION_SMOKE_FAIL_ON_BLOCKING:-0}"

if [[ ! -d "$input_dir" ]]; then
  echo "[integration-smoke-report] artifact directory not found: $input_dir" >&2
  exit 1
fi

dart run tool/integration_smoke_report.dart \
  --input-dir "$input_dir" \
  --output "$output_file" \
  --fail-on-blocking "$fail_on_blocking"
