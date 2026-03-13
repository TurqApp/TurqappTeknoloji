#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

COMMON_EXCLUDES=(
  --glob
  '!.git/**'
  --glob
  '!functions/node_modules/**'
  --glob
  '!cloudflare-shortlink-worker/node_modules/**'
  --glob
  '!ios/Pods/**'
  --glob
  '!build/**'
  --glob
  '!**/*.md'
  --glob
  '!scripts/check_repo_security_regressions.sh'
)

check_literal() {
  local label="$1"
  local pattern="$2"

  if rg -n --fixed-strings "${COMMON_EXCLUDES[@]}" "$pattern" .; then
    echo
    echo "[FAIL] $label"
    return 1
  fi

  echo "[PASS] $label"
  return 0
}

failures=0

check_literal "Hardcoded legacy NETGSM usercode bulunmadi" "3326062598" || failures=$((failures + 1))
check_literal "Hardcoded legacy NETGSM parola bulunmadi" "BursCity42@" || failures=$((failures + 1))
check_literal "Hardcoded App Check debug token setenv geri gelmedi" 'setenv("FIRAAppCheckDebugToken"' || failures=$((failures + 1))
check_literal "Runner scheme icinde App Check debug env geri gelmedi" "FIRAAppCheckDebugToken" || failures=$((failures + 1))
check_literal "Genis iOS ATS acilimi geri gelmedi" "NSAllowsArbitraryLoads" || failures=$((failures + 1))
check_literal "App Check gevsetme flag'i geri gelmedi" "enforceAppCheck: false" || failures=$((failures + 1))
check_literal "Current user cache tekrar ham toJson ile yazilmiyor" "jsonEncode(user.toJson())" || failures=$((failures + 1))
check_literal "Legacy cache sifresi tekrar hydrate edilmiyor" "sifre: json['sifre'] ?? ''" || failures=$((failures + 1))
check_literal "Auth akisinda ham email logu geri gelmedi" 'print("Email: ${signInEmail.value}")' || failures=$((failures + 1))
check_literal "Auth akisinda parola uzunlugu logu geri gelmedi" 'print("Şifre: ${'"'"'*'"'"' * password.value.length}")' || failures=$((failures + 1))
check_literal "Auth akisinda UID logu geri gelmedi" 'print("Giriş başarılı! Kullanıcı UID: ${userCredential.user?.uid}")' || failures=$((failures + 1))

if [[ "$failures" -gt 0 ]]; then
  echo
  echo "Security regression scan failed with $failures finding(s)."
  exit 1
fi

echo
echo "Security regression scan passed."
