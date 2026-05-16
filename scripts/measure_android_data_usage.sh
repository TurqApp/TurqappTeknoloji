#!/usr/bin/env bash
set -euo pipefail

DEVICE_ID="${DEVICE_ID:-}"
PACKAGE_NAME="${PACKAGE_NAME:-com.turqapp.app}"
BASELINE_FILE="${BASELINE_FILE:-/tmp/turqapp_android_data_usage.baseline}"
ADB_BIN="${ADB_BIN:-/Users/turqapp/Library/Android/sdk/platform-tools/adb}"

adb_args=()
if [[ -n "$DEVICE_ID" ]]; then
  adb_args=(-s "$DEVICE_ID")
fi

adb_cmd() {
  if ((${#adb_args[@]})); then
    "$ADB_BIN" "${adb_args[@]}" "$@"
  else
    "$ADB_BIN" "$@"
  fi
}

adb_shell() {
  adb_cmd shell "$@"
}

resolve_uid() {
  local line uid
  line="$(adb_shell pm list packages -U "$PACKAGE_NAME" 2>/dev/null | tr -d '\r' | head -n 1 || true)"
  uid="$(printf '%s\n' "$line" | sed -n 's/.*uid:\([0-9][0-9]*\).*/\1/p')"
  if [[ -n "$uid" ]]; then
    printf '%s\n' "$uid"
    return 0
  fi

  line="$(adb_shell dumpsys package "$PACKAGE_NAME" 2>/dev/null | tr -d '\r' | sed -n 's/.*userId=\([0-9][0-9]*\).*/\1/p' | head -n 1 || true)"
  if [[ -n "$line" ]]; then
    printf '%s\n' "$line"
    return 0
  fi

  return 1
}

bytes_to_mb() {
  awk -v bytes="$1" 'BEGIN { printf "%.2f", bytes / 1024 / 1024 }'
}

snapshot_from_netstats() {
  local uid="$1"
  adb_shell dumpsys netstats detail 2>/dev/null | tr -d '\r' | awk -v uid="$uid" '
    function extract_number(line, key,    pattern, value) {
      pattern = key "=[0-9]+"
      if (match(line, pattern)) {
        value = substr(line, RSTART + length(key) + 1, RLENGTH - length(key) - 1)
        return value + 0
      }
      return 0
    }

    /^  ident=/ {
      in_target = ($0 ~ ("uid=" uid " ") && $0 ~ /tag=0x0/)
      current_type = ""
      if ($0 ~ /\{type=1,/) {
        current_type = "wifi"
      } else if ($0 ~ /\{type=0,/) {
        current_type = "mobile"
      }
      next
    }

    in_target && /^[[:space:]]+st=/ {
      rx = extract_number($0, "rb")
      tx = extract_number($0, "tb")
      total_rx += rx
      total_tx += tx
      if (current_type == "wifi") {
        wifi_rx += rx
        wifi_tx += tx
      } else if (current_type == "mobile") {
        mobile_rx += rx
        mobile_tx += tx
      }
      next
    }

    END {
      if (total_rx == "" && total_tx == "") exit 2
      printf "%d %d %d %d %d %d\n",
        total_rx + 0, total_tx + 0,
        wifi_rx + 0, wifi_tx + 0,
        mobile_rx + 0, mobile_tx + 0
    }
  ' || adb_shell dumpsys netstats 2>/dev/null | tr -d '\r' | awk -v uid="$uid" '
    $1 == "mAppUidStatsMap:" { app = 1; next }
    app && $1 == "uid" { next }
    app && NF == 0 { app = 0 }
    app && $1 == uid {
      total_rx += $2
      total_tx += $4
    }

    $1 == "mStatsMapA:" || $1 == "mStatsMapB:" { iface = 1; next }
    iface && $1 == "ifaceIndex" { next }
    iface && NF == 0 { iface = 0 }
    iface && $4 == uid && $3 == "0x0" {
      if ($2 == "wlan0") {
        wifi_rx += $6
        wifi_tx += $8
      } else if ($2 ~ /^(rmnet|ccmni|ccemni|pdp|vt_data|rmnet_data)/) {
        mobile_rx += $6
        mobile_tx += $8
      }
    }

    END {
      if (total_rx == "" && total_tx == "") exit 2
      printf "%d %d %d %d %d %d\n",
        total_rx + 0, total_tx + 0,
        wifi_rx + 0, wifi_tx + 0,
        mobile_rx + 0, mobile_tx + 0
    }
  '
}

snapshot_from_xt_qtaguid() {
  local uid="$1"
  adb_shell "cat /proc/net/xt_qtaguid/stats 2>/dev/null || true" | tr -d '\r' | awk -v uid="$uid" '
    $4 == uid {
      total_rx += $6
      total_tx += $8
      if ($2 == "wlan0") {
        wifi_rx += $6
        wifi_tx += $8
      } else if ($2 ~ /^(rmnet|ccmni|ccemni|pdp|vt_data|rmnet_data)/) {
        mobile_rx += $6
        mobile_tx += $8
      }
    }
    END {
      if (total_rx == "" && total_tx == "") exit 2
      printf "%d %d %d %d %d %d\n",
        total_rx + 0, total_tx + 0,
        wifi_rx + 0, wifi_tx + 0,
        mobile_rx + 0, mobile_tx + 0
    }
  '
}

snapshot() {
  local uid="$1"
  snapshot_from_netstats "$uid" || snapshot_from_xt_qtaguid "$uid"
}

print_signal() {
  local label="$1"
  local epoch="$2"
  local uid="$3"
  local total_rx="$4"
  local total_tx="$5"
  local wifi_rx="$6"
  local wifi_tx="$7"
  local mobile_rx="$8"
  local mobile_tx="$9"
  local total_bytes=$((total_rx + total_tx))
  local wifi_bytes=$((wifi_rx + wifi_tx))
  local mobile_bytes=$((mobile_rx + mobile_tx))

  printf '[DATA_USAGE_SIGNAL] label=%s package=%s uid=%s epoch=%s totalBytes=%s totalMB=%s wifiBytes=%s wifiMB=%s mobileBytes=%s mobileMB=%s rxBytes=%s txBytes=%s\n' \
    "$label" "$PACKAGE_NAME" "$uid" "$epoch" \
    "$total_bytes" "$(bytes_to_mb "$total_bytes")" \
    "$wifi_bytes" "$(bytes_to_mb "$wifi_bytes")" \
    "$mobile_bytes" "$(bytes_to_mb "$mobile_bytes")" \
    "$total_rx" "$total_tx"
}

read_current() {
  local label="$1"
  local uid epoch values
  uid="$(resolve_uid)" || {
    echo "[DATA_USAGE_SIGNAL] label=$label package=$PACKAGE_NAME status=package_not_installed" >&2
    exit 1
  }
  epoch="$(date +%s)"
  values="$(snapshot "$uid")" || {
    echo "[DATA_USAGE_SIGNAL] label=$label package=$PACKAGE_NAME uid=$uid status=stats_unavailable" >&2
    exit 1
  }
  # shellcheck disable=SC2086
  print_signal "$label" "$epoch" "$uid" $values
}

write_baseline() {
  local uid epoch values
  uid="$(resolve_uid)" || {
    echo "[DATA_USAGE_SIGNAL] label=baseline package=$PACKAGE_NAME status=package_not_installed" >&2
    exit 1
  }
  epoch="$(date +%s)"
  values="$(snapshot "$uid")" || {
    echo "[DATA_USAGE_SIGNAL] label=baseline package=$PACKAGE_NAME uid=$uid status=stats_unavailable" >&2
    exit 1
  }
  printf '%s %s %s\n' "$epoch" "$uid" "$values" > "$BASELINE_FILE"
  # shellcheck disable=SC2086
  print_signal "baseline" "$epoch" "$uid" $values
}

compare_with_baseline() {
  if [[ ! -f "$BASELINE_FILE" ]]; then
    echo "[DATA_USAGE_SIGNAL] label=delta status=missing_baseline file=$BASELINE_FILE" >&2
    exit 1
  fi

  local b_epoch b_uid b_total_rx b_total_tx b_wifi_rx b_wifi_tx b_mobile_rx b_mobile_tx
  read -r b_epoch b_uid b_total_rx b_total_tx b_wifi_rx b_wifi_tx b_mobile_rx b_mobile_tx < "$BASELINE_FILE"

  local uid epoch values
  uid="$(resolve_uid)" || {
    echo "[DATA_USAGE_SIGNAL] label=delta package=$PACKAGE_NAME status=package_not_installed" >&2
    exit 1
  }
  if [[ "$uid" != "$b_uid" ]]; then
    echo "[DATA_USAGE_SIGNAL] label=delta package=$PACKAGE_NAME status=uid_changed baselineUid=$b_uid currentUid=$uid" >&2
    exit 1
  fi
  epoch="$(date +%s)"
  values="$(snapshot "$uid")" || {
    echo "[DATA_USAGE_SIGNAL] label=delta package=$PACKAGE_NAME uid=$uid status=stats_unavailable" >&2
    exit 1
  }

  local c_total_rx c_total_tx c_wifi_rx c_wifi_tx c_mobile_rx c_mobile_tx
  read -r c_total_rx c_total_tx c_wifi_rx c_wifi_tx c_mobile_rx c_mobile_tx <<< "$values"

  print_signal "current" "$epoch" "$uid" \
    "$c_total_rx" "$c_total_tx" "$c_wifi_rx" "$c_wifi_tx" "$c_mobile_rx" "$c_mobile_tx"

  local d_total_rx=$((c_total_rx - b_total_rx))
  local d_total_tx=$((c_total_tx - b_total_tx))
  local d_wifi_rx=$((c_wifi_rx - b_wifi_rx))
  local d_wifi_tx=$((c_wifi_tx - b_wifi_tx))
  local d_mobile_rx=$((c_mobile_rx - b_mobile_rx))
  local d_mobile_tx=$((c_mobile_tx - b_mobile_tx))
  print_signal "delta" "$epoch" "$uid" \
    "$d_total_rx" "$d_total_tx" "$d_wifi_rx" "$d_wifi_tx" "$d_mobile_rx" "$d_mobile_tx"
  printf '[DATA_USAGE_SIGNAL] label=elapsed seconds=%s baselineEpoch=%s currentEpoch=%s\n' \
    "$((epoch - b_epoch))" "$b_epoch" "$epoch"
}

usage() {
  cat <<USAGE
Usage: DEVICE_ID=<adb-id> $0 baseline|sample|delta

baseline  Save current package counters to $BASELINE_FILE.
sample    Print current package counters.
delta     Print current counters and delta from the saved baseline.

Output lines are prefixed with [DATA_USAGE_SIGNAL] so QA logs can grep them.
USAGE
}

case "${1:-sample}" in
  baseline) write_baseline ;;
  sample) read_current "sample" ;;
  delta) compare_with_baseline ;;
  *) usage; exit 2 ;;
esac
