#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ -f ".env.integration.local" ]]; then
  set -a
  source ".env.integration.local"
  set +a
fi

source "scripts/integration_device_resolver.sh"
source "scripts/integration_seed_helper.sh"

: "${INTEGRATION_LOGIN_EMAIL:?set INTEGRATION_LOGIN_EMAIL}"
: "${INTEGRATION_LOGIN_PASSWORD:?set INTEGRATION_LOGIN_PASSWORD}"

TARGET_PLATFORM="${INTEGRATION_TARGET_PLATFORM:-android}"
DEVICE_ID="$(resolve_integration_device_id "${TARGET_PLATFORM}")"

seed_integration_fixture_if_enabled
trap 'reset_integration_fixture_if_enabled' EXIT

COMMON_ARGS=(
  test
  --no-pub
  --dart-define=RUN_INTEGRATION_SMOKE=true
  --dart-define=INTEGRATION_DETERMINISTIC_STARTUP=true
  --dart-define=INTEGRATION_SUPPRESS_PERIODIC_SIDE_EFFECTS=true
  --dart-define=INTEGRATION_SKIP_BACKGROUND_STARTUP_WORK=true
  --dart-define=INTEGRATION_USE_OS_PERMISSION_STATE=true
  "--dart-define=INTEGRATION_LOGIN_EMAIL=${INTEGRATION_LOGIN_EMAIL}"
  "--dart-define=INTEGRATION_LOGIN_PASSWORD=${INTEGRATION_LOGIN_PASSWORD}"
  -d
  "${DEVICE_ID}"
)

run_case() {
  local state="$1"
  local target="$2"
  echo "[permission-os-matrix] state=${state} target=$(basename "$target")"
  bash scripts/configure_os_permissions.sh "$TARGET_PLATFORM" "$state" "$DEVICE_ID"
  flutter "${COMMON_ARGS[@]}" "$target"
}

echo "[permission-os-matrix] platform=${TARGET_PLATFORM}"
echo "[permission-os-matrix] device=${DEVICE_ID}"
run_case denied integration_test/system/permission_os_denied_state_smoke_test.dart
run_case granted integration_test/system/permission_os_granted_state_smoke_test.dart
echo "[permission-os-matrix] suite passed"
