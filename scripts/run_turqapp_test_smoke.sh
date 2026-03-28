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
ARTIFACT_DIR="${INTEGRATION_SMOKE_ARTIFACT_DIR:-artifacts/integration_smoke}"
ANDROID_PACKAGE="${INTEGRATION_SMOKE_ANDROID_PACKAGE:-com.turqapp.app}"
ANDROID_REMOTE_ARTIFACT_DIR="${INTEGRATION_SMOKE_ANDROID_REMOTE_ARTIFACT_DIR:-files/integration_smoke}"
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

rm -rf "$ARTIFACT_DIR"
mkdir -p "$ARTIFACT_DIR"

write_host_stub_artifact() {
  local scenario="$1"
  local test_status="$2"
  local output_file="$ARTIFACT_DIR/${scenario}.json"

  local failure_json='{}'
  if [[ "$test_status" -ne 0 ]]; then
    failure_json="$(node -e "process.stdout.write(JSON.stringify({message: 'smoke test exited with code ' + process.argv[1], source: 'host_stub'}))" "$test_status")"
  fi

  cat >"$output_file" <<EOF
{
  "scenario": "$scenario",
  "probe": {
    "currentRoute": "",
    "previousRoute": ""
  },
  "telemetry": {
    "registered": false,
    "thresholdReport": {
      "issues": []
    }
  },
  "invariants": {
    "registered": false,
    "count": 0,
    "violations": []
  },
  "failure": $failure_json,
  "artifactStatus": {
    "source": "host_stub",
    "exported": false,
    "reason": "android_package_uninstalled_after_suite"
  }
}
EOF
}

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

if [[ "$TARGET_PLATFORM" == "android" && -n "$DEVICE_ID" ]]; then
  if /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$DEVICE_ID" shell pm path "$ANDROID_PACKAGE" >/dev/null 2>&1; then
    /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$DEVICE_ID" \
      shell run-as "$ANDROID_PACKAGE" rm -rf "$ANDROID_REMOTE_ARTIFACT_DIR" >/dev/null 2>&1 || true
    /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$DEVICE_ID" \
      shell run-as "$ANDROID_PACKAGE" mkdir -p "$ANDROID_REMOTE_ARTIFACT_DIR" >/dev/null 2>&1 || true
  fi
fi

for test_file in "${suite_tests[@]}"; do
  echo "[turqapp-test] suite=$(basename "$test_file" .dart)"
  scenario_name="$(basename "$test_file" .dart)"
  test_status=0
  if ! flutter "${COMMON_ARGS[@]}" "$test_file"; then
    test_status=1
  fi
  if [[ "$TARGET_PLATFORM" == "android" && -n "$DEVICE_ID" ]]; then
    if /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$DEVICE_ID" shell pm path "$ANDROID_PACKAGE" >/dev/null 2>&1; then
      while IFS= read -r remote_name; do
        [[ -n "$remote_name" ]] || continue
        /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$DEVICE_ID" \
          exec-out run-as "$ANDROID_PACKAGE" cat "$ANDROID_REMOTE_ARTIFACT_DIR/$remote_name" \
          >"$ARTIFACT_DIR/$remote_name"
      done < <(
        /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$DEVICE_ID" \
          shell run-as "$ANDROID_PACKAGE" ls "$ANDROID_REMOTE_ARTIFACT_DIR" 2>/dev/null |
          tr -d '\r' |
          grep -E '\.(json|png)$' || true
      )
    fi
  fi
  if [[ ! -f "$ARTIFACT_DIR/${scenario_name}.json" ]]; then
    write_host_stub_artifact "$scenario_name" "$test_status"
  fi
  if [[ "$test_status" -ne 0 ]]; then
    if [[ -d "$ARTIFACT_DIR" ]]; then
      echo "[turqapp-test] failure artifacts:"
      find "$ARTIFACT_DIR" -maxdepth 1 -type f \
        \( -name '*.json' -o -name '*.png' \) -print | sort
      while IFS= read -r artifact_json; do
        echo "[turqapp-test] artifact_json=${artifact_json}"
        sed -n '1,220p' "$artifact_json"
      done < <(find "$ARTIFACT_DIR" -maxdepth 1 -type f -name '*.json' | sort)
    fi
    exit 1
  fi
done

echo "[turqapp-test] all suites passed"
