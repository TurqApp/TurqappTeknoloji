#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

source "scripts/test_suite_manifest.sh"
source "scripts/integration_device_resolver.sh"
source "scripts/integration_seed_helper.sh"

if [[ -f ".env.integration.local" ]]; then
  set -a
  source ".env.integration.local"
  set +a
fi

: "${INTEGRATION_LOGIN_EMAIL:?set INTEGRATION_LOGIN_EMAIL}"
: "${INTEGRATION_LOGIN_PASSWORD:?set INTEGRATION_LOGIN_PASSWORD}"

TARGET_PLATFORM="${INTEGRATION_TARGET_PLATFORM:-android}"
DEVICE_ID="$(resolve_integration_device_id "${TARGET_PLATFORM}")"
MANIFEST="config/test_suites/turqapp_test_smoke.txt"

mapfile -t suite_tests < <(load_suite_entries "$MANIFEST")

seed_integration_fixture_if_enabled
trap 'reset_integration_fixture_if_enabled' EXIT

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

echo "[turqapp-test] platform=${TARGET_PLATFORM}"
echo "[turqapp-test] device=${DEVICE_ID}"
echo "[turqapp-test] manifest=${MANIFEST} count=${#suite_tests[@]}"
for test_file in "${suite_tests[@]}"; do
  echo "[turqapp-test] suite=$(basename "$test_file" .dart)"
  flutter "${COMMON_ARGS[@]}" "$test_file"
done

echo "[turqapp-test] all suites passed"
