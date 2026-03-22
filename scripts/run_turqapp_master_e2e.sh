#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f ".env.integration.local" ]]; then
  set -a
  source ".env.integration.local"
  set +a
fi

source "scripts/test_suite_manifest.sh"

DEVICE_ID="${INTEGRATION_SMOKE_DEVICE_ID:-192.168.1.196:5555}"
LOGIN_EMAIL="${INTEGRATION_LOGIN_EMAIL:?set INTEGRATION_LOGIN_EMAIL}"
LOGIN_PASSWORD="${INTEGRATION_LOGIN_PASSWORD:?set INTEGRATION_LOGIN_PASSWORD}"
MANIFEST="config/test_suites/release_gate_e2e.txt"

mapfile -t suite_tests < <(load_suite_entries "$MANIFEST")

run_test() {
  local target="$1"
  echo "[release-gate-e2e] running $target"
  flutter test "$target" \
    -d "$DEVICE_ID" \
    --dart-define=RUN_INTEGRATION_SMOKE=true \
    --dart-define=INTEGRATION_LOGIN_EMAIL="$LOGIN_EMAIL" \
    --dart-define=INTEGRATION_LOGIN_PASSWORD="$LOGIN_PASSWORD"
}

echo "[release-gate-e2e] manifest=$MANIFEST count=${#suite_tests[@]}"
for test_file in "${suite_tests[@]}"; do
  run_test "$test_file"
done

echo "[release-gate-e2e] all tests passed"
