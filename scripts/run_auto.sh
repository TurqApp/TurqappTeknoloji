#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

LOG_DIR="$ROOT_DIR/.runlogs"
PID_FILE="$LOG_DIR/auto_run.pids"
mkdir -p "$LOG_DIR"

ANDROID_ID="${ANDROID_DEVICE_ID:-}"
IOS_ID="${IOS_DEVICE_ID:-}"

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
  echo "Android cihaz bulunamadi. ORNEK: ANDROID_DEVICE_ID=192.168.1.147:5555 ./scripts/run_auto.sh"
  exit 1
fi

if [[ -z "$IOS_ID" ]]; then
  echo "iOS cihaz bulunamadi. ORNEK: IOS_DEVICE_ID=00008140-000C0D903488801C ./scripts/run_auto.sh"
  exit 1
fi

if [[ -f "$PID_FILE" ]]; then
  while IFS='=' read -r _pid_name _pid; do
    if [[ -n "${_pid:-}" ]] && kill -0 "$_pid" 2>/dev/null; then
      echo "Halihazirda calisan otomatik run var (PID: $_pid). Once sonlandir: ./scripts/stop_auto_runs.sh"
      exit 1
    fi
  done < "$PID_FILE"
fi

ANDROID_LOG="$LOG_DIR/android_$(date +%Y%m%d_%H%M%S).log"
IOS_LOG="$LOG_DIR/ios_release_$(date +%Y%m%d_%H%M%S).log"

echo "Android run baslatiliyor: $ANDROID_ID"
nohup bash -lc "flutter run -d \"$ANDROID_ID\" --no-pub" >"$ANDROID_LOG" 2>&1 < /dev/null &
ANDROID_PID=$!
disown "$ANDROID_PID" 2>/dev/null || true

echo "iOS release run baslatiliyor: $IOS_ID"
nohup bash -lc "flutter run --release -d \"$IOS_ID\" --no-pub" >"$IOS_LOG" 2>&1 < /dev/null &
IOS_PID=$!
disown "$IOS_PID" 2>/dev/null || true

cat > "$PID_FILE" <<PIDS
ANDROID_PID=$ANDROID_PID
IOS_PID=$IOS_PID
PIDS

echo "Tamam."
echo "Android PID: $ANDROID_PID | Log: $ANDROID_LOG"
echo "iOS PID: $IOS_PID | Log: $IOS_LOG"
echo "Durum: ps -p $ANDROID_PID,$IOS_PID"
echo "Canli log: tail -f $ANDROID_LOG $IOS_LOG"
echo "Durdur: ./scripts/stop_auto_runs.sh"
