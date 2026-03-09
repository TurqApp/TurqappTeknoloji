#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"
cd "$ROOT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a git repository: $ROOT_DIR" >&2
  exit 1
fi

tmp_file="$(mktemp)"
git status --porcelain=v1 >"$tmp_file"

tracked_total="$(grep -E '^( M|M |A |D |R )' "$tmp_file" | wc -l | tr -d ' ')"
untracked_total="$(grep -E '^\?\?' "$tmp_file" | wc -l | tr -d ' ')"

node_modules_dirty="$(grep -E '(^( M|M |A |D |R )|^\?\?) functions/node_modules/' "$tmp_file" | wc -l | tr -d ' ')"
ios_dirty="$(grep -E '(^( M|M |A |D |R )|^\?\?) ios/' "$tmp_file" | wc -l | tr -d ' ')"
lib_dirty="$(grep -E '(^( M|M |A |D |R )|^\?\?) lib/' "$tmp_file" | wc -l | tr -d ' ')"
functions_dirty="$(grep -E '(^( M|M |A |D |R )|^\?\?) functions/' "$tmp_file" | wc -l | tr -d ' ')"

echo "=== Dirty Audit ==="
echo "Tracked dirty     : $tracked_total"
echo "Untracked dirty   : $untracked_total"
echo "functions/*       : $functions_dirty"
echo "functions/node_modules/*: $node_modules_dirty"
echo "ios/*             : $ios_dirty"
echo "lib/*             : $lib_dirty"
echo

echo "=== Likely Generated / Local Noise ==="
grep -E '(^( M|M |A |D |R )|^\?\?) (functions/node_modules/|\.idea/|\.runlogs/|.*\.log$|ios/Pods/|build/)' "$tmp_file" || true
echo

echo "=== Likely Real Source Changes (node_modules and local noise excluded) ==="
grep -E '(^( M|M |A |D |R )|^\?\?) ' "$tmp_file" \
  | grep -Ev 'functions/node_modules/|\.idea/|\.runlogs/|.*\.log$|ios/Pods/|build/' \
  || true
echo

echo "=== Top Dirty Paths (first 120) ==="
sed -E 's/^(.. )//' "$tmp_file" | sed -n '1,120p'

rm -f "$tmp_file"
