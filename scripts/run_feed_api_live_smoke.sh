#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

: "${FEED_API_SMOKE_URL:?set FEED_API_SMOKE_URL}"

ARGS=(
  test
  --no-pub
  --dart-define=RUN_REAL_API_SMOKE=true
  "--dart-define=FEED_API_SMOKE_URL=${FEED_API_SMOKE_URL}"
  test/unit/services/feed_api_live_smoke_test.dart
)

if [[ -n "${FEED_API_SMOKE_BEARER:-}" ]]; then
  ARGS+=("--dart-define=FEED_API_SMOKE_BEARER=${FEED_API_SMOKE_BEARER}")
fi
if [[ -n "${FEED_API_SMOKE_ITEMS_KEY:-}" ]]; then
  ARGS+=("--dart-define=FEED_API_SMOKE_ITEMS_KEY=${FEED_API_SMOKE_ITEMS_KEY}")
fi
if [[ -n "${FEED_API_SMOKE_VIDEO_KEY:-}" ]]; then
  ARGS+=("--dart-define=FEED_API_SMOKE_VIDEO_KEY=${FEED_API_SMOKE_VIDEO_KEY}")
fi

echo "[feed-api-live-smoke] url=${FEED_API_SMOKE_URL}"
flutter "${ARGS[@]}"
