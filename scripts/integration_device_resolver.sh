#!/usr/bin/env bash

resolve_integration_device_id() {
  local platform="${1:-android}"
  local explicit="${INTEGRATION_SMOKE_DEVICE_ID:-}"
  if [[ -n "$explicit" ]]; then
    printf '%s\n' "$explicit"
    return 0
  fi

  local devices_output
  devices_output="$(flutter devices)"

  local resolved=""
  case "$platform" in
    ios)
      resolved="$(printf '%s\n' "$devices_output" | awk -F ' • ' '/• ios/ {print $2; exit}')"
      ;;
    android)
      resolved="$(printf '%s\n' "$devices_output" | awk -F ' • ' '/• android/ {print $2; exit}')"
      if [[ -z "$resolved" ]]; then
        resolved="192.168.1.196:5555"
      fi
      ;;
    any)
      resolved="$(printf '%s\n' "$devices_output" | awk -F ' • ' '/• (android|ios)/ {print $2; exit}')"
      ;;
    *)
      echo "unsupported integration target platform: $platform" >&2
      return 1
      ;;
  esac

  if [[ -z "$resolved" ]]; then
    echo "no $platform device found via flutter devices" >&2
    return 1
  fi

  printf '%s\n' "$resolved"
}
