#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ -f ".env.integration.local" ]]; then
  set -a
  source ".env.integration.local"
  set +a
fi

source "scripts/test_suite_manifest.sh"

: "${INTEGRATION_LOGIN_EMAIL:?set INTEGRATION_LOGIN_EMAIL}"
: "${INTEGRATION_LOGIN_PASSWORD:?set INTEGRATION_LOGIN_PASSWORD}"

DEVICE_ID="${INTEGRATION_SMOKE_DEVICE_ID:-192.168.1.196:5555}"
MANIFEST="config/test_suites/extended_smoke.txt"

mapfile -t suite_tests < <(load_suite_entries "$MANIFEST")

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

echo "[extended-e2e] device=${DEVICE_ID}"
echo "[extended-e2e] manifest=${MANIFEST} count=${#suite_tests[@]}"

for test_file in "${suite_tests[@]}"; do
  echo "[extended-e2e] running $(basename "$test_file")"
  flutter "${COMMON_ARGS[@]}" "$test_file"
done

echo "[extended-e2e] all suites passed"
