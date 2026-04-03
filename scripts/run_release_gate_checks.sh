#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

run_integration_smoke="${RUN_INTEGRATION_SMOKE:-1}"
run_auth_session_regression="${RUN_AUTH_SESSION_REGRESSION:-1}"
run_product_depth_e2e="${RUN_PRODUCT_DEPTH_E2E:-1}"
run_process_death_restore="${RUN_PROCESS_DEATH_RESTORE:-1}"
run_rules_runtime_regression="${RUN_RULES_RUNTIME_REGRESSION:-1}"
run_app_version_config_check="${RUN_APP_VERSION_CONFIG_CHECK:-auto}"
smoke_fail_on_blocking="${INTEGRATION_SMOKE_FAIL_ON_BLOCKING:-1}"
telemetry_fail_on_blocking="${TELEMETRY_FAIL_ON_BLOCKING:-0}"
release_alert_require_webhook="${RELEASE_ALERT_REQUIRE_WEBHOOK:-1}"

echo "[1/14] flutter analyze --no-fatal-infos"
flutter analyze --no-fatal-infos

echo "[2/14] flutter test"
flutter test

echo "[3/14] app integration smoke"
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

echo "[4/14] auth/session/feed regression"
if [[ "$run_auth_session_regression" == "1" ]]; then
  bash scripts/run_auth_session_feed_regression.sh
else
  echo "[auth-session-regression] skipped by explicit RUN_AUTH_SESSION_REGRESSION=0"
fi

echo "[5/14] product depth e2e"
if [[ "$run_product_depth_e2e" == "1" ]]; then
  bash scripts/run_product_depth_e2e.sh
else
  echo "[product-depth-e2e] skipped by explicit RUN_PRODUCT_DEPTH_E2E=0"
fi

echo "[6/14] process death restore"
if [[ "$run_process_death_restore" == "1" ]]; then
  bash scripts/run_process_death_restore_suite.sh
else
  echo "[process-death-restore] skipped by explicit RUN_PROCESS_DEATH_RESTORE=0"
fi

echo "[7/14] rules/runtime regression"
if [[ "$run_rules_runtime_regression" == "1" ]]; then
  bash scripts/run_rules_runtime_regression.sh
else
  echo "[rules-runtime-regression] skipped by explicit RUN_RULES_RUNTIME_REGRESSION=0"
fi

echo "[8/14] functions npm test"
(cd functions && npm test)

echo "[9/14] functions npm run test:rules"
(cd functions && npm run test:rules)

echo "[10/14] functions npm run build"
(cd functions && npm run build)

echo "[11/14] cloudflare-shortlink-worker npm test"
(cd cloudflare-shortlink-worker && npm test)

echo "[12/14] security regression guard"
bash scripts/check_repo_security_regressions.sh

echo "[13/14] architecture guard"
bash scripts/check_architecture_guards.sh

echo "[14/14] app version config"
case "$run_app_version_config_check" in
  1|true|TRUE|yes|YES)
    node scripts/set_app_version_config.mjs --verify-only=true
    ;;
  auto|AUTO)
    if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
      node scripts/set_app_version_config.mjs --verify-only=true
    else
      echo "[app-version-config] skipped (GOOGLE_APPLICATION_CREDENTIALS not set)"
    fi
    ;;
  *)
    echo "[app-version-config] skipped by explicit RUN_APP_VERSION_CONFIG_CHECK=${run_app_version_config_check}"
    ;;
esac

echo "[telemetry-threshold-report]"
TELEMETRY_FAIL_ON_BLOCKING="$telemetry_fail_on_blocking" \
  bash scripts/export_telemetry_threshold_report.sh

echo "[device-log-report]"
bash scripts/export_android_device_log_report.sh

source scripts/load_release_alert_env.sh

if [[ "$release_alert_require_webhook" == "1" ]] && [[ -z "${RELEASE_ALERT_WEBHOOK_URL:-}" ]]; then
  echo "[release-alert] RELEASE_ALERT_WEBHOOK_URL is required for release gate" >&2
  exit 1
fi

echo "[release-alert-bundle]"
bash scripts/export_release_alert_bundle.sh

echo "[release-alert-message]"
bash scripts/export_release_alert_message.sh

echo "[release-alert-post]"
RELEASE_ALERT_FAIL_ON_POST_ERROR="${RELEASE_ALERT_FAIL_ON_POST_ERROR:-1}" \
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
