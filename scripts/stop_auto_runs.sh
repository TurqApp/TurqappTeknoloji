#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$ROOT_DIR/.runlogs/auto_run.pids"

if [[ ! -f "$PID_FILE" ]]; then
  echo "PID dosyasi yok: $PID_FILE"
  exit 0
fi

# shellcheck disable=SC1090
source "$PID_FILE"

for pid in "${ANDROID_PID:-}" "${IOS_PID:-}"; do
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid"
    echo "Durduruldu: $pid"
  fi
done

rm -f "$PID_FILE"
echo "Tamam."
