#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "[1/7] flutter analyze --no-fatal-infos"
flutter analyze --no-fatal-infos

echo "[2/7] flutter test"
flutter test

echo "[3/7] functions npm test"
(cd functions && npm test)

echo "[4/7] functions npm run test:rules"
(cd functions && npm run test:rules)

echo "[5/7] functions npm run build"
(cd functions && npm run build)

echo "[6/7] cloudflare-shortlink-worker npm test"
(cd cloudflare-shortlink-worker && npm test)

echo "[7/7] security regression guard"
bash scripts/check_repo_security_regressions.sh

if [[ "${RUN_K6_SMOKE:-0}" == "1" ]]; then
  echo "[k6] smoke profile"
  k6 run \
    --env FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-turqappteknoloji}" \
    --env SEARCH_CF_BASE_URL="${SEARCH_CF_BASE_URL:-https://us-central1-turqappteknoloji.cloudfunctions.net}" \
    --env INTERACTION_CF_BASE_URL="${INTERACTION_CF_BASE_URL:-https://europe-west1-turqappteknoloji.cloudfunctions.net}" \
    --env ID_TOKEN="${ID_TOKEN:-}" \
    --env TOGGLE_LIKE_ENDPOINT="${TOGGLE_LIKE_ENDPOINT:-}" \
    --env RECORD_VIEW_ENDPOINT="${RECORD_VIEW_ENDPOINT:-}" \
    --env K6_PROFILE=smoke \
    --env K6_MODE="${K6_MODE:-search_only}" \
    tests/load/k6_turqapp_load_test.js
else
  echo "[k6] skipped (set RUN_K6_SMOKE=1 to execute)"
fi
