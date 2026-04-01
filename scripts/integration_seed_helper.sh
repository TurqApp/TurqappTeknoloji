#!/usr/bin/env bash

seed_integration_fixture_if_enabled() {
  if [[ "${INTEGRATION_AUTO_SEED:-0}" != "1" ]]; then
    return 0
  fi

  local fixture_file="${INTEGRATION_SEED_FILE:-integration_test/core/fixtures/smoke_seed.device_baseline.json}"
  local state_file="${INTEGRATION_SEED_STATE_FILE:-artifacts/integration_seed/seed_state.json}"
  local require_seed="${INTEGRATION_REQUIRE_SEED:-0}"

  if [[ ! -f "$fixture_file" ]]; then
    echo "[integration-seed] fixture file not found: $fixture_file" >&2
    if [[ "$require_seed" == "1" ]]; then
      return 1
    fi
    return 0
  fi

  mkdir -p "$(dirname "$state_file")"
  export INTEGRATION_SEED_STATE_FILE="$state_file"
  echo "[integration-seed] applying fixture: $fixture_file"
  node functions/scripts/seed_integration_fixture.mjs "$fixture_file"
}

reset_integration_fixture_if_enabled() {
  if [[ "${INTEGRATION_AUTO_SEED:-0}" != "1" ]]; then
    return 0
  fi

  local state_file="${INTEGRATION_SEED_STATE_FILE:-artifacts/integration_seed/seed_state.json}"
  if [[ ! -f "$state_file" ]]; then
    return 0
  fi

  echo "[integration-seed] resetting fixture state"
  node functions/scripts/reset_integration_fixture.mjs "$state_file"
}
