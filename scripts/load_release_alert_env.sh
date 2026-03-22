#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

env_file="${RELEASE_ALERT_ENV_FILE:-scripts/release_alert_webhook.env}"

if [[ ! -f "$env_file" ]]; then
  exit 0
fi

set -a
# shellcheck disable=SC1090
source "$env_file"
set +a
