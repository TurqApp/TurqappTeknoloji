#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PROJECT_ID="${FIREBASE_PROJECT_ID:-turqappteknoloji}"
PROFILE="${K6_PROFILE:-smoke}"
MODE="${K6_MODE:-feed_only}"
SUMMARY_FILE="${K6_SUMMARY_FILE:-artifacts/k6/k6_summary.json}"
ID_TOKEN_VALUE="${ID_TOKEN:-}"
TOGGLE_LIKE_URL="${TOGGLE_LIKE_ENDPOINT:-}"
RECORD_VIEW_URL="${RECORD_VIEW_ENDPOINT:-https://europe-west1-${PROJECT_ID}.cloudfunctions.net/recordViewBatch}"

if ! command -v k6 >/dev/null 2>&1; then
  echo "[k6-smoke] k6 binary not found"
  exit 1
fi

if [[ -z "$ID_TOKEN_VALUE" ]]; then
  echo "[k6-smoke] skipped (ID_TOKEN not set)"
  exit 0
fi

if [[ "$MODE" == "interaction_only" && -z "$TOGGLE_LIKE_URL" ]]; then
  echo "[k6-smoke] interaction_only requires TOGGLE_LIKE_ENDPOINT"
  exit 1
fi

mkdir -p "$(dirname "$SUMMARY_FILE")"

echo "[k6-smoke] profile=${PROFILE} mode=${MODE} project=${PROJECT_ID}"

k6 run \
  --summary-export "${SUMMARY_FILE}" \
  --env FIREBASE_PROJECT_ID="${PROJECT_ID}" \
  --env SEARCH_CF_BASE_URL="${SEARCH_CF_BASE_URL:-https://us-central1-${PROJECT_ID}.cloudfunctions.net}" \
  --env INTERACTION_CF_BASE_URL="${INTERACTION_CF_BASE_URL:-https://europe-west1-${PROJECT_ID}.cloudfunctions.net}" \
  --env ID_TOKEN="${ID_TOKEN_VALUE}" \
  --env TOGGLE_LIKE_ENDPOINT="${TOGGLE_LIKE_URL}" \
  --env RECORD_VIEW_ENDPOINT="${RECORD_VIEW_URL}" \
  --env K6_PROFILE="${PROFILE}" \
  --env K6_MODE="${MODE}" \
  tests/load/k6_turqapp_load_test.js

echo "[k6-smoke] summary=${SUMMARY_FILE}"
