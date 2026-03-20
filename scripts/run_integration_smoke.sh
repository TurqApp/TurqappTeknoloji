#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fixture_file="${INTEGRATION_FIXTURE_FILE:-}"
fixture_json="${INTEGRATION_FIXTURE_JSON:-}"

if [[ -n "$fixture_file" ]]; then
  if [[ ! -f "$fixture_file" ]]; then
    echo "[integration-smoke] fixture file not found: $fixture_file" >&2
    exit 1
  fi
  fixture_json="$(node -e "const fs=require('fs');const p=process.argv[1];const raw=JSON.parse(fs.readFileSync(p,'utf8'));process.stdout.write(JSON.stringify(raw));" "$fixture_file")"
fi

declare -a smoke_tests=(
  "integration_test/feed_resume_test.dart"
  "integration_test/explore_preview_gate_test.dart"
  "integration_test/profile_resume_test.dart"
  "integration_test/short_refresh_preserve_test.dart"
  "integration_test/notifications_snapshot_mutation_test.dart"
)

declare -a flutter_args=(
  "test"
  "--dart-define=RUN_INTEGRATION_SMOKE=true"
  "--dart-define=INTEGRATION_DETERMINISTIC_STARTUP=true"
  "--dart-define=INTEGRATION_SUPPRESS_PERIODIC_SIDE_EFFECTS=true"
  "--dart-define=INTEGRATION_SKIP_BACKGROUND_STARTUP_WORK=true"
)

if [[ -n "$fixture_json" ]]; then
  flutter_args+=("--dart-define=INTEGRATION_FIXTURE_JSON=$fixture_json")
  echo "[integration-smoke] using fixture contract"
  if [[ -n "$fixture_file" ]]; then
    echo "[integration-smoke] fixture file: $fixture_file"
  fi
else
  echo "[integration-smoke] fixture contract not provided; continuity-only assertions active"
fi

echo "[integration-smoke] running ${#smoke_tests[@]} smoke tests"
flutter "${flutter_args[@]}" "${smoke_tests[@]}"
