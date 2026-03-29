#!/usr/bin/env bash

trim_integration_device_id() {
  local value="${1:-}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

resolve_integration_device_id() {
  local platform="${1:-android}"
  local explicit="${INTEGRATION_SMOKE_DEVICE_ID:-}"
  if [[ -n "$explicit" ]]; then
    trim_integration_device_id "$explicit"
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

  trim_integration_device_id "$resolved"
}
