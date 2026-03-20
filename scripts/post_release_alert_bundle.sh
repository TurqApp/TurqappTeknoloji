#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

bundle_file="${RELEASE_ALERT_BUNDLE_OUTPUT:-artifacts/release_alert_bundle_latest.json}"
webhook_url="${RELEASE_ALERT_WEBHOOK_URL:-}"
fail_on_post_error="${RELEASE_ALERT_FAIL_ON_POST_ERROR:-0}"

if [[ -z "$webhook_url" ]]; then
  echo "[release-alert-post] skipped (set RELEASE_ALERT_WEBHOOK_URL to execute)"
  exit 0
fi

if [[ ! -f "$bundle_file" ]]; then
  echo "[release-alert-post] bundle file not found: $bundle_file" >&2
  exit 1
fi

set +e
curl -sS \
  -X POST \
  -H "content-type: application/json" \
  --data-binary @"$bundle_file" \
  "$webhook_url"
post_status=$?
set -e

if [[ "$post_status" -ne 0 ]]; then
  echo "[release-alert-post] webhook post failed with exit code $post_status" >&2
  if [[ "$fail_on_post_error" == "1" ]]; then
    exit "$post_status"
  fi
  exit 0
fi

echo
echo "[release-alert-post] bundle delivered"
