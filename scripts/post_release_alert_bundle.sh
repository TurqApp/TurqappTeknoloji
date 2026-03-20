#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

bundle_file="${RELEASE_ALERT_BUNDLE_OUTPUT:-artifacts/release_alert_bundle_latest.json}"
webhook_url="${RELEASE_ALERT_WEBHOOK_URL:-}"
fail_on_post_error="${RELEASE_ALERT_FAIL_ON_POST_ERROR:-0}"
payload_format="${RELEASE_ALERT_PAYLOAD_FORMAT:-}"
webhook_provider="${RELEASE_ALERT_WEBHOOK_PROVIDER:-}"

if [[ -z "$webhook_url" ]]; then
  echo "[release-alert-post] skipped (set RELEASE_ALERT_WEBHOOK_URL to execute)"
  exit 0
fi

if [[ ! -f "$bundle_file" ]]; then
  echo "[release-alert-post] bundle file not found: $bundle_file" >&2
  exit 1
fi

if [[ -z "$payload_format" ]]; then
  case "${webhook_provider,,}" in
    slack)
      payload_format="slack"
      ;;
    discord)
      payload_format="discord"
      ;;
    teams|msteams)
      payload_format="teams"
      ;;
    *)
      payload_format="raw"
      ;;
  esac
fi

severity="$(node -e "const fs=require('fs');const raw=JSON.parse(fs.readFileSync(process.argv[1],'utf8'));process.stdout.write(String(raw.summary?.severity || 'unknown'));" "$bundle_file")"
headline="$(node -e "const fs=require('fs');const raw=JSON.parse(fs.readFileSync(process.argv[1],'utf8'));const text=String(raw.summary?.headline || 'release alert').replace(/[\\r\\n]+/g,' ').slice(0,180);process.stdout.write(text);" "$bundle_file")"
payload="$(dart run tool/release_alert_message.dart --input "$bundle_file" --format "$payload_format")"

set +e
curl -sS \
  -X POST \
  -H "content-type: application/json" \
  -H "x-release-alert-format: $payload_format" \
  -H "x-release-alert-severity: $severity" \
  -H "x-release-alert-headline: $headline" \
  --data "$payload" \
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
