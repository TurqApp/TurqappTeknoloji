#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

LCOV_FILE="${1:-coverage/lcov.info}"
MIN_COVERAGE="${MIN_FLUTTER_COVERAGE:-70}"

if [[ ! -f "$LCOV_FILE" ]]; then
  echo "[coverage] missing lcov file: $LCOV_FILE" >&2
  exit 1
fi

coverage_percent="$(
  awk '
    BEGIN { found=0; lh=0; lf=0 }
    /^LH:/ { lh += substr($0, 4); found=1 }
    /^LF:/ { lf += substr($0, 4); found=1 }
    END {
      if (!found || lf == 0) {
        print "0.00"
      } else {
        printf "%.2f", (lh / lf) * 100
      }
    }
  ' "$LCOV_FILE"
)"

echo "[coverage] total=${coverage_percent}% min=${MIN_COVERAGE}%"

awk -v coverage="$coverage_percent" -v minimum="$MIN_COVERAGE" '
  BEGIN {
    if (coverage + 0 < minimum + 0) {
      exit 1
    }
  }
'
