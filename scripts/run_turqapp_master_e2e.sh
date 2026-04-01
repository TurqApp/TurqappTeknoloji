#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

export INTEGRATION_TEST_MANIFEST="${INTEGRATION_TEST_MANIFEST:-config/test_suites/release_gate_e2e.txt}"

exec bash scripts/run_turqapp_test_smoke.sh
