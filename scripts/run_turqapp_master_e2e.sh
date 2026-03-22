#!/bin/bash
set -euo pipefail

DEVICE_ID="${INTEGRATION_SMOKE_DEVICE_ID:-192.168.1.196:5555}"
LOGIN_EMAIL="${INTEGRATION_LOGIN_EMAIL:-turqapp@gmail.com}"
LOGIN_PASSWORD="${INTEGRATION_LOGIN_PASSWORD:-Nisa1512.}"

cd "$(dirname "$0")/.."

flutter test integration_test/turqapp_master_e2e_test.dart \
  -d "$DEVICE_ID" \
  --dart-define=RUN_INTEGRATION_SMOKE=true \
  --dart-define=INTEGRATION_LOGIN_EMAIL="$LOGIN_EMAIL" \
  --dart-define=INTEGRATION_LOGIN_PASSWORD="$LOGIN_PASSWORD"
