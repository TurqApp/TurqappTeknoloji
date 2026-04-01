#!/bin/sh
set -eu

if [ "${PLATFORM_NAME:-}" != "iphoneos" ]; then
  exit 0
fi

FRAMEWORK_DIR="${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Frameworks/objective_c.framework"
BINARY_PATH="${FRAMEWORK_DIR}/objective_c"

existing_platform=""
if [ -f "$BINARY_PATH" ]; then
  existing_platform="$(
    /usr/bin/otool -l "$BINARY_PATH" 2>/dev/null |
      /usr/bin/awk '/LC_BUILD_VERSION/{found=1} found && $1=="platform"{print $2; exit}'
  )"
fi

if [ "$existing_platform" = "2" ]; then
  exit 0
fi

/bin/rm -rf "$FRAMEWORK_DIR"

PROJECT_ROOT="${FLUTTER_APPLICATION_PATH:-${SOURCE_ROOT}/..}"
HOOKS_DIR="${PROJECT_ROOT}/.dart_tool/hooks_runner/objective_c"

latest_input=""
latest_mtime=0
for input in "$HOOKS_DIR"/*/input.json; do
  [ -f "$input" ] || continue
  if ! /usr/bin/grep -q '"target_sdk": "iphoneos"' "$input"; then
    continue
  fi
  mtime="$(/usr/bin/stat -f '%m' "$input" 2>/dev/null || echo 0)"
  if [ "$mtime" -gt "$latest_mtime" ]; then
    latest_mtime="$mtime"
    latest_input="$input"
  fi
done

[ -n "$latest_input" ] || exit 0

output_json="${latest_input%/input.json}/output.json"
[ -f "$output_json" ] || exit 0

SOURCE_DYLIB="$(
  /usr/bin/sed -n 's/.*"file": "\([^"]*\)".*/\1/p' "$output_json" |
    /usr/bin/head -n 1
)"

[ -n "$SOURCE_DYLIB" ] || exit 0
[ -f "$SOURCE_DYLIB" ] || exit 0

/bin/mkdir -p "$FRAMEWORK_DIR"
/bin/cp -f "$SOURCE_DYLIB" "$BINARY_PATH"
/usr/bin/install_name_tool -id '@rpath/objective_c.framework/objective_c' "$BINARY_PATH"

/bin/cat > "$FRAMEWORK_DIR/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>objective_c</string>
	<key>CFBundleIdentifier</key>
	<string>io.flutter.flutter.native-assets.objective-c</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>objective_c</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>1.0</string>
	<key>MinimumOSVersion</key>
	<string>13.0</string>
</dict>
</plist>
EOF
