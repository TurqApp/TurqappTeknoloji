#!/usr/bin/env bash
set -euo pipefail

platform="${1:?usage: configure_os_permissions.sh <android|ios> <denied|granted> [device_id] [package_id]}"
state="${2:?usage: configure_os_permissions.sh <android|ios> <denied|granted> [device_id] [package_id]}"
device_id="${3:-${INTEGRATION_SMOKE_DEVICE_ID:-}}"
package_id="${4:-com.turqapp.app}"

android_revoke_permission() {
  local permission="$1"
  /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$device_id" shell pm revoke "$package_id" "$permission" >/dev/null 2>&1 || true
}

android_grant_permission() {
  local permission="$1"
  /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$device_id" shell pm grant "$package_id" "$permission" >/dev/null 2>&1 || true
}

android_set_appop() {
  local op="$1"
  local mode="$2"
  /Users/turqapp/Library/Android/sdk/platform-tools/adb -s "$device_id" shell appops set "$package_id" "$op" "$mode" >/dev/null 2>&1 || true
}

ios_privacy() {
  local action="$1"
  local service="$2"
  xcrun simctl privacy "$device_id" "$action" "$service" "$package_id" >/dev/null 2>&1 || true
}

if [[ -z "$device_id" ]]; then
  echo "[os-permissions] device id is required" >&2
  exit 1
fi

case "$platform" in
  android)
    echo "[os-permissions] android state=$state device=$device_id"
    if [[ "$state" == "denied" ]]; then
      android_revoke_permission android.permission.CAMERA
      android_revoke_permission android.permission.RECORD_AUDIO
      android_revoke_permission android.permission.READ_MEDIA_IMAGES
      android_revoke_permission android.permission.READ_MEDIA_VIDEO
      android_revoke_permission android.permission.READ_EXTERNAL_STORAGE
      android_set_appop CAMERA ignore
      android_set_appop RECORD_AUDIO ignore
      android_set_appop READ_MEDIA_IMAGES ignore
      android_set_appop READ_MEDIA_VIDEO ignore
      android_set_appop READ_EXTERNAL_STORAGE ignore
    else
      android_grant_permission android.permission.CAMERA
      android_grant_permission android.permission.RECORD_AUDIO
      android_grant_permission android.permission.READ_MEDIA_IMAGES
      android_grant_permission android.permission.READ_MEDIA_VIDEO
      android_grant_permission android.permission.READ_EXTERNAL_STORAGE
      android_set_appop CAMERA allow
      android_set_appop RECORD_AUDIO allow
      android_set_appop READ_MEDIA_IMAGES allow
      android_set_appop READ_MEDIA_VIDEO allow
      android_set_appop READ_EXTERNAL_STORAGE allow
    fi
    ;;
  ios)
    echo "[os-permissions] ios state=$state device=$device_id"
    if [[ "$state" == "denied" ]]; then
      ios_privacy revoke camera
      ios_privacy revoke microphone
      ios_privacy revoke photos
    else
      ios_privacy grant camera
      ios_privacy grant microphone
      ios_privacy grant photos
    fi
    ;;
  *)
    echo "[os-permissions] unsupported platform: $platform" >&2
    exit 1
    ;;
esac
