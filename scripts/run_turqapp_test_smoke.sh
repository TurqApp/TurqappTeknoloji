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

export INTEGRATION_AUTO_SEED="${INTEGRATION_AUTO_SEED:-1}"
export INTEGRATION_REQUIRE_SEED="${INTEGRATION_REQUIRE_SEED:-1}"

: "${INTEGRATION_LOGIN_EMAIL:?set INTEGRATION_LOGIN_EMAIL}"
: "${INTEGRATION_LOGIN_PASSWORD:?set INTEGRATION_LOGIN_PASSWORD}"

TARGET_PLATFORM="${INTEGRATION_TARGET_PLATFORM:-android}"
DEVICE_ID="$(resolve_integration_device_id "${TARGET_PLATFORM}")"
MANIFEST="${INTEGRATION_TEST_MANIFEST:-config/test_suites/release_gate_e2e.txt}"
default_fixture_file="integration_test/core/fixtures/smoke_fixture.device_baseline.json"
fixture_file="${INTEGRATION_FIXTURE_FILE:-}"
fixture_json="${INTEGRATION_FIXTURE_JSON:-}"

if [[ ! -f "$MANIFEST" ]]; then
  echo "[turqapp-test] manifest not found: $MANIFEST" >&2
  exit 1
fi

if [[ -z "$fixture_file" && -f "$default_fixture_file" ]]; then
  fixture_file="$default_fixture_file"
fi

if [[ -n "$fixture_file" ]]; then
  if [[ ! -f "$fixture_file" ]]; then
    echo "[turqapp-test] fixture file not found: $fixture_file" >&2
    exit 1
  fi
  fixture_json="$(node -e "const fs=require('fs');const p=process.argv[1];const raw=JSON.parse(fs.readFileSync(p,'utf8'));process.stdout.write(JSON.stringify(raw));" "$fixture_file")"
fi

rm -rf "artifacts/integration_smoke"

suite_tests=()
if [[ "$MANIFEST" == *.tsv ]]; then
  while IFS= read -r suite_entry; do
    IFS='|' read -r test_file _ <<<"$suite_entry"
    suite_tests+=("$test_file")
  done < <(load_suite_pairs "$MANIFEST")
else
  while IFS= read -r suite_entry; do
    suite_tests+=("$suite_entry")
  done < <(load_suite_entries "$MANIFEST")
fi

seed_integration_fixture_if_enabled
trap 'reset_integration_fixture_if_enabled' EXIT

COMMON_ARGS=(
  test
  --no-pub
  --reporter=expanded
  --dart-define=RUN_INTEGRATION_SMOKE=true
  --dart-define=INTEGRATION_DETERMINISTIC_STARTUP=true
  --dart-define=INTEGRATION_SUPPRESS_PERIODIC_SIDE_EFFECTS=true
  --dart-define=INTEGRATION_SKIP_BACKGROUND_STARTUP_WORK=true
  "--dart-define=INTEGRATION_LOGIN_EMAIL=${INTEGRATION_LOGIN_EMAIL}"
  "--dart-define=INTEGRATION_LOGIN_PASSWORD=${INTEGRATION_LOGIN_PASSWORD}"
  -d
  "${DEVICE_ID}"
)

if [[ -n "$fixture_json" ]]; then
  COMMON_ARGS+=("--dart-define=INTEGRATION_FIXTURE_JSON=${fixture_json}")
fi

echo "[turqapp-test] platform=${TARGET_PLATFORM}"
echo "[turqapp-test] device=${DEVICE_ID}"
echo "[turqapp-test] manifest=${MANIFEST} count=${#suite_tests[@]}"
if [[ -n "$fixture_file" ]]; then
  echo "[turqapp-test] fixture=${fixture_file}"
fi
for test_file in "${suite_tests[@]}"; do
  echo "[turqapp-test] suite=$(basename "$test_file" .dart)"
  if ! flutter "${COMMON_ARGS[@]}" "$test_file"; then
    if [[ -d "artifacts/integration_smoke" ]]; then
      echo "[turqapp-test] failure artifacts:"
      find "artifacts/integration_smoke" -maxdepth 1 -type f \
        \( -name '*.json' -o -name '*.png' \) -print | sort
      while IFS= read -r artifact_json; do
        echo "[turqapp-test] artifact_json=${artifact_json}"
        sed -n '1,220p' "$artifact_json"
      done < <(find "artifacts/integration_smoke" -maxdepth 1 -type f -name '*.json' | sort)
    fi
    exit 1
  fi
done

echo "[turqapp-test] all suites passed"
