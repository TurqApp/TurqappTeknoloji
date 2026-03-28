#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export INTEGRATION_TEST_MANIFEST="${INTEGRATION_TEST_MANIFEST:-config/test_suites/auth_session_feed_regression.txt}"

exec bash scripts/run_turqapp_test_smoke.sh
