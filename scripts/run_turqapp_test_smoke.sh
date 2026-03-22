#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ -f ".env.integration.local" ]]; then
  set -a
  source ".env.integration.local"
  set +a
fi

: "${INTEGRATION_LOGIN_EMAIL:?set INTEGRATION_LOGIN_EMAIL}"
: "${INTEGRATION_LOGIN_PASSWORD:?set INTEGRATION_LOGIN_PASSWORD}"

DEVICE_ID="${INTEGRATION_SMOKE_DEVICE_ID:-192.168.1.196:5555}"

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

echo "[turqapp-test] device=${DEVICE_ID}"
echo "[turqapp-test] suite=feed_production_smoke_suite"
flutter "${COMMON_ARGS[@]}" integration_test/feed/feed_production_smoke_suite_test.dart

echo "[turqapp-test] suite=hls_data_usage_suite"
flutter "${COMMON_ARGS[@]}" integration_test/feed/hls_data_usage_suite_test.dart

echo "[turqapp-test] suite=feed_black_flash_smoke"
flutter "${COMMON_ARGS[@]}" integration_test/feed/feed_black_flash_smoke_test.dart

echo "[turqapp-test] suite=feed_network_resilience_smoke"
flutter "${COMMON_ARGS[@]}" integration_test/feed/feed_network_resilience_smoke_test.dart

echo "[turqapp-test] suite=feed_resume_smoke"
flutter "${COMMON_ARGS[@]}" integration_test/feed/feed_resume_test.dart

echo "[turqapp-test] all suites passed"
