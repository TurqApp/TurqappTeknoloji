#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "[1/8] flutter analyze --no-fatal-infos"
flutter analyze --no-fatal-infos

echo "[2/8] flutter test"
flutter test

echo "[3/8] app integration smoke"
if [[ "${RUN_INTEGRATION_SMOKE:-0}" == "1" ]]; then
  bash scripts/run_integration_smoke.sh
else
  echo "[integration-smoke] skipped (set RUN_INTEGRATION_SMOKE=1 to execute)"
fi

echo "[4/8] functions npm test"
(cd functions && npm test)

echo "[5/8] functions npm run test:rules"
(cd functions && npm run test:rules)

echo "[6/8] functions npm run build"
(cd functions && npm run build)

echo "[7/8] cloudflare-shortlink-worker npm test"
(cd cloudflare-shortlink-worker && npm test)

echo "[8/8] security regression guard"
bash scripts/check_repo_security_regressions.sh

if [[ "${RUN_K6_SMOKE:-0}" == "1" ]]; then
  echo "[k6] smoke profile"
  if [[ -z "${ID_TOKEN:-}" ]]; then
    echo "[k6] anlamli smoke icin ID_TOKEN gerekiyor; bu tur atlandi"
    exit 0
  fi
  K6_MODE_VALUE="${K6_MODE:-feed_only}"
  k6 run \
    --env FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-turqappteknoloji}" \
    --env SEARCH_CF_BASE_URL="${SEARCH_CF_BASE_URL:-https://us-central1-turqappteknoloji.cloudfunctions.net}" \
    --env INTERACTION_CF_BASE_URL="${INTERACTION_CF_BASE_URL:-https://europe-west1-turqappteknoloji.cloudfunctions.net}" \
    --env ID_TOKEN="${ID_TOKEN:-}" \
    --env TOGGLE_LIKE_ENDPOINT="${TOGGLE_LIKE_ENDPOINT:-}" \
    --env RECORD_VIEW_ENDPOINT="${RECORD_VIEW_ENDPOINT:-}" \
    --env K6_PROFILE=smoke \
    --env K6_MODE="${K6_MODE_VALUE}" \
    tests/load/k6_turqapp_load_test.js
else
  echo "[k6] skipped (set RUN_K6_SMOKE=1 to execute)"
fi
