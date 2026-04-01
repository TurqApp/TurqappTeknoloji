#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

LCOV_FILE="${1:-coverage/lcov.info}"
POLICY_FILE="${FLUTTER_COVERAGE_POLICY_FILE:-config/quality/flutter_coverage_policy.env}"
TARGET_COVERAGE="${TARGET_FLUTTER_COVERAGE:-70}"
MIN_BASELINE_COVERAGE="${MIN_FLUTTER_COVERAGE_BASELINE:-}"
ENFORCE_TARGET_COVERAGE="${ENFORCE_FLUTTER_COVERAGE_TARGET:-1}"
REPORT_FILE="${FLUTTER_COVERAGE_REPORT_FILE:-coverage/coverage_gate_report.txt}"

if [[ -f "$POLICY_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$POLICY_FILE"
fi

TARGET_COVERAGE="${TARGET_FLUTTER_COVERAGE:-${TARGET_COVERAGE}}"
MIN_BASELINE_COVERAGE="${MIN_FLUTTER_COVERAGE_BASELINE:-${MIN_BASELINE_COVERAGE:-0}}"
ENFORCE_TARGET_COVERAGE="${ENFORCE_FLUTTER_COVERAGE_TARGET:-${ENFORCE_TARGET_COVERAGE}}"

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

mkdir -p "$(dirname "$REPORT_FILE")"

write_report() {
  local status="$1"
  local message="$2"

  cat >"$REPORT_FILE" <<EOF
status=${status}
coverage_total=${coverage_percent}
coverage_minimum=${MIN_BASELINE_COVERAGE}
coverage_target=${TARGET_COVERAGE}
enforce_target=${ENFORCE_TARGET_COVERAGE}
lcov_file=${LCOV_FILE}
message=${message}
EOF
}

echo "[coverage] total=${coverage_percent}% baseline=${MIN_BASELINE_COVERAGE}% target=${TARGET_COVERAGE}% enforce_target=${ENFORCE_TARGET_COVERAGE}"

if awk -v coverage="$coverage_percent" -v minimum="$MIN_BASELINE_COVERAGE" 'BEGIN { exit !(coverage + 0 < minimum + 0) }'; then
  write_report "fail" "coverage dropped below minimum baseline"
  echo "[coverage] fail: coverage ${coverage_percent}% is below minimum baseline ${MIN_BASELINE_COVERAGE}%." >&2
  exit 1
fi

if [[ "$ENFORCE_TARGET_COVERAGE" == "1" ]]; then
  if awk -v coverage="$coverage_percent" -v target="$TARGET_COVERAGE" 'BEGIN { exit !(coverage + 0 < target + 0) }'; then
    write_report "fail" "coverage below enforced target"
    echo "[coverage] fail: coverage ${coverage_percent}% is below enforced target ${TARGET_COVERAGE}%." >&2
    exit 1
  fi
else
  if awk -v coverage="$coverage_percent" -v target="$TARGET_COVERAGE" 'BEGIN { exit !(coverage + 0 < target + 0) }'; then
    echo "[coverage] target warning: coverage ${coverage_percent}% is below non-enforced target ${TARGET_COVERAGE}%."
  fi
fi

write_report "pass" "coverage policy satisfied"
echo "[coverage] target achieved."
