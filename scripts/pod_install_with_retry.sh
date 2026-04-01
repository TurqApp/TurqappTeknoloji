#!/bin/bash
set -euo pipefail

max_attempts="${POD_INSTALL_MAX_ATTEMPTS:-3}"
sleep_seconds="${POD_INSTALL_RETRY_SLEEP_SECONDS:-15}"

if [[ ! -d ios ]]; then
  echo "[pod-install] ios directory not found"
  exit 1
fi

cd ios

attempt=1
while (( attempt <= max_attempts )); do
  echo "[pod-install] attempt ${attempt}/${max_attempts}"

  if pod install; then
    echo "[pod-install] success"
    exit 0
  fi

  if (( attempt == max_attempts )); then
    echo "[pod-install] failed after ${max_attempts} attempts"
    exit 1
  fi

  echo "[pod-install] transient failure detected, retrying in ${sleep_seconds}s"
  sleep "${sleep_seconds}"
  attempt=$((attempt + 1))
done
