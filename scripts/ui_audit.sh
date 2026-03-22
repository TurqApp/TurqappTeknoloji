#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUT_FILE="${1:-docs/ui_audit_latest.md}"
mkdir -p "$(dirname "$OUT_FILE")"

count_matches() {
  local pattern="$1"
  (rg -n --no-heading "$pattern" lib || true) | wc -l | tr -d ' '
}

collect_top_files() {
  local pattern="$1"
  local limit="$2"
  (rg -n --no-heading "$pattern" lib || true) \
    | cut -d: -f1 \
    | sort \
    | uniq -c \
    | sort -nr \
    | head -n "$limit"
}

ELLIPSIS_COUNT="$(count_matches 'TextOverflow\.ellipsis')"
MAXLINES1_COUNT="$(count_matches 'maxLines:\s*1\b')"
FIXED_HEIGHT_COUNT="$(count_matches 'height:\s*[0-9]{2,}(\.[0-9]+)?\s*,')"
FIXED_WIDTH_COUNT="$(count_matches 'width:\s*[0-9]{2,}(\.[0-9]+)?\s*,')"
POSITIONED_COUNT="$(count_matches 'Positioned\(')"
SHRINKWRAP_COUNT="$(count_matches 'shrinkWrap:\s*true')"
NESTED_SCROLL_LOCK_COUNT="$(count_matches 'NeverScrollableScrollPhysics\(')"

SMALL_SCREEN_CANDIDATES="$(collect_top_files 'height:\s*[0-9]{3,}(\.[0-9]+)?\s*,|width:\s*[0-9]{3,}(\.[0-9]+)?\s*,' 20)"
ELLIPSIS_TOP="$(collect_top_files 'TextOverflow\.ellipsis|maxLines:\s*1\b' 20)"

cat > "$OUT_FILE" <<EOF
# UI Audit Report

Generated at: $(date +"%Y-%m-%d %H:%M:%S %Z")
Scope: \`lib/**\`

## Summary Counts
- TextOverflow.ellipsis: **$ELLIPSIS_COUNT**
- maxLines:1: **$MAXLINES1_COUNT**
- fixed height literals: **$FIXED_HEIGHT_COUNT**
- fixed width literals: **$FIXED_WIDTH_COUNT**
- Positioned widgets: **$POSITIONED_COUNT**
- shrinkWrap:true: **$SHRINKWRAP_COUNT**
- NeverScrollableScrollPhysics: **$NESTED_SCROLL_LOCK_COUNT**

## Top Files (Text Clipping Risk)
\`\`\`text
$ELLIPSIS_TOP
\`\`\`

## Top Files (Small Screen Risk)
\`\`\`text
$SMALL_SCREEN_CANDIDATES
\`\`\`

## Notes
- This audit is static. It does not change app behavior.
- Prioritize files that are high in both sections above.
- Validate final fixes on:
  - <=360dp
  - 361-412dp
  - >412dp
  - text scale 1.0 / 1.3 / 1.6
EOF

echo "UI audit written to: $OUT_FILE"
