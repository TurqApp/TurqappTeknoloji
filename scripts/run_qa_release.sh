#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

LOG_DIR="$ROOT_DIR/.runlogs"
PID_FILE="$LOG_DIR/auto_run.pids"
mkdir -p "$LOG_DIR"

ANDROID_ID="${ANDROID_DEVICE_ID:-}"
IOS_ID="${IOS_DEVICE_ID:-}"
QA_FLAGS=(
  "--dart-define=QA_LAB_ENABLED=true"
  "--dart-define=QA_LAB_AUTOSTART=true"
  "--dart-define=QA_LAB_FRESH_START=true"
)

if [[ -z "$ANDROID_ID" || -z "$IOS_ID" ]]; then
  DEVICES_OUTPUT="$(flutter devices)"

  if [[ -z "$ANDROID_ID" ]]; then
    ANDROID_ID="$(printf '%s\n' "$DEVICES_OUTPUT" | awk -F ' • ' '/• android/ {print $2; exit}')"
  fi

  if [[ -z "$IOS_ID" ]]; then
    IOS_ID="$(printf '%s\n' "$DEVICES_OUTPUT" | awk -F ' • ' '/• ios/ {print $2; exit}')"
  fi
fi

if [[ -z "$ANDROID_ID" ]]; then
  echo "Android cihaz bulunamadi."
  exit 1
fi

if [[ -z "$IOS_ID" ]]; then
  echo "iOS cihaz bulunamadi."
  exit 1
fi

if [[ -f "$PID_FILE" ]]; then
  "$ROOT_DIR/scripts/stop_auto_runs.sh" || true
fi

ANDROID_LOG="$LOG_DIR/android_qa_release_$(date +%Y%m%d_%H%M%S).log"
IOS_LOG="$LOG_DIR/ios_qa_release_$(date +%Y%m%d_%H%M%S).log"

/Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$ANDROID_ID" logcat -c || true

echo "Android QA release run baslatiliyor: $ANDROID_ID"
nohup bash -lc "cd \"$ROOT_DIR\" && flutter run --release -d \"$ANDROID_ID\" --no-pub ${QA_FLAGS[*]}" >"$ANDROID_LOG" 2>&1 < /dev/null &
ANDROID_PID=$!
disown "$ANDROID_PID" 2>/dev/null || true

echo "iOS QA release run baslatiliyor: $IOS_ID"
nohup bash -lc "cd \"$ROOT_DIR\" && flutter run --release -d \"$IOS_ID\" --no-pub ${QA_FLAGS[*]}" >"$IOS_LOG" 2>&1 < /dev/null &
IOS_PID=$!
disown "$IOS_PID" 2>/dev/null || true

cat > "$PID_FILE" <<PIDS
ANDROID_PID=$ANDROID_PID
IOS_PID=$IOS_PID
PIDS

echo "Tamam."
echo "Android PID: $ANDROID_PID | Log: $ANDROID_LOG"
echo "iOS PID: $IOS_PID | Log: $IOS_LOG"
echo "Canli log: tail -f $ANDROID_LOG $IOS_LOG"
