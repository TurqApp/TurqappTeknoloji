#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

source scripts/load_release_alert_env.sh

bundle_file="${RELEASE_ALERT_BUNDLE_OUTPUT:-artifacts/release_alert_bundle_latest.json}"
webhook_url="${RELEASE_ALERT_WEBHOOK_URL:-}"
fail_on_post_error="${RELEASE_ALERT_FAIL_ON_POST_ERROR:-0}"
payload_format="${RELEASE_ALERT_PAYLOAD_FORMAT:-}"
webhook_provider="${RELEASE_ALERT_WEBHOOK_PROVIDER:-}"
webhook_bearer_token="${RELEASE_ALERT_WEBHOOK_BEARER_TOKEN:-}"
webhook_header_name="${RELEASE_ALERT_WEBHOOK_HEADER_NAME:-}"
webhook_header_value="${RELEASE_ALERT_WEBHOOK_HEADER_VALUE:-}"
connect_timeout="${RELEASE_ALERT_CONNECT_TIMEOUT_SECONDS:-10}"
max_time="${RELEASE_ALERT_MAX_TIME_SECONDS:-30}"
retry_count="${RELEASE_ALERT_RETRY_COUNT:-2}"

if [[ -z "$webhook_url" ]]; then
  echo "[release-alert-post] skipped (set RELEASE_ALERT_WEBHOOK_URL to execute)"
  exit 0
fi

if [[ ! -f "$bundle_file" ]]; then
  echo "[release-alert-post] bundle file not found: $bundle_file" >&2
  exit 1
fi

provider_lower="$(printf '%s' "$webhook_provider" | tr '[:upper:]' '[:lower:]')"
if [[ -z "$payload_format" ]]; then
  case "$provider_lower" in
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

curl_args=(
  -sS
  -X POST
  -H "content-type: application/json"
  -H "x-release-alert-format: $payload_format"
  -H "x-release-alert-severity: $severity"
  -H "x-release-alert-headline: $headline"
  --connect-timeout "$connect_timeout"
  --max-time "$max_time"
  --retry "$retry_count"
  --retry-all-errors
  --data "$payload"
  "$webhook_url"
)

if [[ -n "$webhook_bearer_token" ]]; then
  curl_args+=(-H "authorization: Bearer $webhook_bearer_token")
fi

if [[ -n "$webhook_header_name" && -n "$webhook_header_value" ]]; then
  curl_args+=(-H "$webhook_header_name: $webhook_header_value")
fi

set +e
curl "${curl_args[@]}"
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
