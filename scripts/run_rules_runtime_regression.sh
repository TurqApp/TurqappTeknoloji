#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

manifest="${RULES_RUNTIME_MANIFEST:-config/test_suites/rules_runtime_regression.txt}"
smoke_report_output="${RULES_RUNTIME_SMOKE_REPORT_OUTPUT:-artifacts/rules_runtime_regression_smoke_report.json}"

echo "[rules-runtime-regression] functions security regressions"
(
  cd functions
  npm run test:security-regressions
)

echo "[rules-runtime-regression] android emulator smoke"
INTEGRATION_TEST_MANIFEST="$manifest" \
  bash scripts/run_turqapp_test_smoke.sh

echo "[rules-runtime-regression] blocking smoke report"
INTEGRATION_SMOKE_REPORT_OUTPUT="$smoke_report_output" \
INTEGRATION_SMOKE_FAIL_ON_BLOCKING=1 \
  bash scripts/export_integration_smoke_report.sh

echo "[rules-runtime-regression] completed"
