#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT/android"

echo "[crash-anr-matrix] running Android playback resilience matrix"
./gradlew :app:connectedDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.class=com.turqapp.app.qa.ExoPlayerCrashAnrMatrixTest
