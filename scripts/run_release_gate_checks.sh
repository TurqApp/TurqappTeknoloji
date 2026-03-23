#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

run_integration_smoke="${RUN_INTEGRATION_SMOKE:-1}"
smoke_fail_on_blocking="${INTEGRATION_SMOKE_FAIL_ON_BLOCKING:-1}"
telemetry_fail_on_blocking="${TELEMETRY_FAIL_ON_BLOCKING:-0}"

echo "[1/8] flutter analyze --no-fatal-infos"
flutter analyze --no-fatal-infos

echo "[2/8] flutter test"
flutter test

echo "[3/8] app integration smoke"
if [[ "$run_integration_smoke" == "1" ]]; then
  bash scripts/run_turqapp_test_smoke.sh
  if [[ -d "artifacts/integration_smoke" ]]; then
    echo "[integration-smoke-report]"
    INTEGRATION_SMOKE_FAIL_ON_BLOCKING="$smoke_fail_on_blocking" \
      bash scripts/export_integration_smoke_report.sh
  else
    echo "[integration-smoke-report] skipped (artifact directory not found)"
  fi
else
  echo "[integration-smoke] skipped by explicit RUN_INTEGRATION_SMOKE=0"
fi

echo "[4/8] functions npm test"
(cd functions && npm test)

echo "[5/8] functions npm run test:rules"
(cd functions && npm run test:rules)

echo "[6/8] functions npm run build"
(cd functions && npm run build)

echo "[7/8] cloudflare-shortlink-worker npm test"
(cd cloudflare-shortlink-worker && npm test)

echo "[8/8] security regression guard"
bash scripts/check_repo_security_regressions.sh

echo "[telemetry-threshold-report]"
TELEMETRY_FAIL_ON_BLOCKING="$telemetry_fail_on_blocking" \
  bash scripts/export_telemetry_threshold_report.sh

echo "[release-alert-bundle]"
bash scripts/export_release_alert_bundle.sh

echo "[release-alert-message]"
bash scripts/export_release_alert_message.sh

echo "[release-alert-post]"
bash scripts/post_release_alert_bundle.sh

if [[ "${RUN_K6_SMOKE:-0}" == "1" ]]; then
  echo "[k6] smoke profile"
  K6_PROFILE="${K6_PROFILE:-smoke}" \
    K6_MODE="${K6_MODE:-feed_only}" \
    K6_SUMMARY_FILE="${K6_SUMMARY_FILE:-artifacts/k6/release_gate_summary.json}" \
    bash scripts/run_k6_smoke.sh
else
  echo "[k6] skipped (set RUN_K6_SMOKE=1 to execute)"
fi
