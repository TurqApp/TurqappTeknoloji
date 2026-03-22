#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f ".env.integration.local" ]]; then
  set -a
  source ".env.integration.local"
  set +a
fi

DEVICE_ID="${INTEGRATION_SMOKE_DEVICE_ID:-192.168.1.196:5555}"
LOGIN_EMAIL="${INTEGRATION_LOGIN_EMAIL:?set INTEGRATION_LOGIN_EMAIL}"
LOGIN_PASSWORD="${INTEGRATION_LOGIN_PASSWORD:?set INTEGRATION_LOGIN_PASSWORD}"

run_test() {
  local target="$1"
  echo "[release-gate-e2e] running $target"
  flutter test "$target" \
    -d "$DEVICE_ID" \
    --dart-define=RUN_INTEGRATION_SMOKE=true \
    --dart-define=INTEGRATION_LOGIN_EMAIL="$LOGIN_EMAIL" \
    --dart-define=INTEGRATION_LOGIN_PASSWORD="$LOGIN_PASSWORD"
}

run_test integration_test/turqapp_complete_e2e_test.dart
run_test integration_test/feed/feed_black_flash_smoke_test.dart
run_test integration_test/feed/feed_fullscreen_audio_smoke_test.dart
run_test integration_test/feed/feed_network_resilience_smoke_test.dart
run_test integration_test/feed/feed_normal_scroll_playback_smoke_test.dart
run_test integration_test/shorts/short_first_two_playback_test.dart
run_test integration_test/feed/turqapp_audio_ownership_e2e_test.dart
run_test integration_test/feed/hls_data_usage_suite_test.dart

echo "[release-gate-e2e] all tests passed"
