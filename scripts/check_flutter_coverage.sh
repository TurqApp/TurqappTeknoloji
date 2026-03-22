#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

LCOV_FILE="${1:-coverage/lcov.info}"
POLICY_FILE="${FLUTTER_COVERAGE_POLICY_FILE:-config/quality/flutter_coverage_policy.env}"
TARGET_COVERAGE="${TARGET_FLUTTER_COVERAGE:-70}"
MIN_BASELINE_COVERAGE="${MIN_FLUTTER_COVERAGE_BASELINE:-}"

if [[ -f "$POLICY_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$POLICY_FILE"
fi

TARGET_COVERAGE="${TARGET_FLUTTER_COVERAGE:-${TARGET_COVERAGE}}"
MIN_BASELINE_COVERAGE="${MIN_FLUTTER_COVERAGE_BASELINE:-${MIN_BASELINE_COVERAGE:-0}}"

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

echo "[coverage] total=${coverage_percent}% baseline=${MIN_BASELINE_COVERAGE}% target=${TARGET_COVERAGE}%"

awk -v coverage="$coverage_percent" -v minimum="$MIN_BASELINE_COVERAGE" '
  BEGIN {
    if (coverage + 0 < minimum + 0) {
      exit 1
    }
  }
'

if awk -v coverage="$coverage_percent" -v target="$TARGET_COVERAGE" 'BEGIN { exit !(coverage + 0 < target + 0) }'; then
  echo "[coverage] legacy baseline gate active; target not met yet, but coverage did not regress."
else
  echo "[coverage] target achieved."
fi
