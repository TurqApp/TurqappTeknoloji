#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f ".env.integration.local" ]]; then
  set -a
  source ".env.integration.local"
  set +a
fi

source "scripts/test_suite_manifest.sh"
source "scripts/integration_device_resolver.sh"
source "scripts/integration_seed_helper.sh"

TARGET_PLATFORM="${INTEGRATION_TARGET_PLATFORM:-android}"
DEVICE_ID="$(resolve_integration_device_id "${TARGET_PLATFORM}")"
LOGIN_EMAIL="${INTEGRATION_LOGIN_EMAIL:?set INTEGRATION_LOGIN_EMAIL}"
LOGIN_PASSWORD="${INTEGRATION_LOGIN_PASSWORD:?set INTEGRATION_LOGIN_PASSWORD}"
MANIFEST="config/test_suites/release_gate_e2e.txt"

mapfile -t suite_tests < <(load_suite_entries "$MANIFEST")

seed_integration_fixture_if_enabled
trap 'reset_integration_fixture_if_enabled' EXIT

run_test() {
  local target="$1"
  echo "[release-gate-e2e] running $target"
  flutter test "$target" \
    -d "$DEVICE_ID" \
    --dart-define=RUN_INTEGRATION_SMOKE=true \
    --dart-define=INTEGRATION_LOGIN_EMAIL="$LOGIN_EMAIL" \
    --dart-define=INTEGRATION_LOGIN_PASSWORD="$LOGIN_PASSWORD"
}

echo "[release-gate-e2e] platform=$TARGET_PLATFORM"
echo "[release-gate-e2e] device=$DEVICE_ID"
echo "[release-gate-e2e] manifest=$MANIFEST count=${#suite_tests[@]}"
for test_file in "${suite_tests[@]}"; do
  run_test "$test_file"
done

echo "[release-gate-e2e] all tests passed"
