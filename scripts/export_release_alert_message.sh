#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

bundle_file="${RELEASE_ALERT_BUNDLE_OUTPUT:-artifacts/release_alert_bundle_latest.json}"
format="${RELEASE_ALERT_PAYLOAD_FORMAT:-}"
provider="${RELEASE_ALERT_WEBHOOK_PROVIDER:-}"
output_file="${RELEASE_ALERT_MESSAGE_OUTPUT:-artifacts/release_alert_message_latest.json}"

if [[ ! -f "$bundle_file" ]]; then
  echo "[release-alert-message] bundle file not found: $bundle_file" >&2
  exit 1
fi

if [[ -z "$format" ]]; then
  case "${provider,,}" in
    slack)
      format="slack"
      ;;
    discord)
      format="discord"
      ;;
    teams|msteams)
      format="teams"
      ;;
    *)
      format="raw"
      ;;
  esac
fi

mkdir -p "$(dirname "$output_file")"
dart run tool/release_alert_message.dart \
  --input "$bundle_file" \
  --format "$format" > "$output_file"

echo "[release-alert-message] wrote $format payload to $output_file"
