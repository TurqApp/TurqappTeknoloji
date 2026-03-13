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
check_literal "Auth akisinda hata mesaji dump'i geri gelmedi" 'print("Giriş hatası oluştu: ${e.code} - ${e.message}")' || failures=$((failures + 1))
check_literal "Sifre guncelleme akisinda hata mesaji dump'i geri gelmedi" 'print("Hata: ${e.code} - ${e.message}")' || failures=$((failures + 1))
check_literal "Notification loglarinda uid dump'i geri gelmedi" 'console.log("onUserNotificationCreate sent", { uid, type, tokenPresent: true });' || failures=$((failures + 1))
check_literal "Current user init logunda uid dump'i geri gelmedi" "print('🔄 Initializing CurrentUserService for user: \${firebaseUser.uid}');" || failures=$((failures + 1))
check_literal "Scholarship detail logunda uid dump'i geri gelmedi" "print('Başvuru durumu kontrol ediliyor: \${currentUser.uid}');" || failures=$((failures + 1))
check_literal "DenemeGrid logunda userID dump'i geri gelmedi" "debugPrint('[DenemeGrid] profile fetch failed for \$userID: \$e');" || failures=$((failures + 1))
check_literal "DenemeGrid logunda docID dump'i geri gelmedi" "debugPrint('[DenemeGrid] applicant count fetch failed for \$docID: \$e');" || failures=$((failures + 1))
check_literal "Hybrid feed logunda authorId dump'i geri gelmedi" 'console.log(`[HybridFeed] Celebrity fan-in: ${authorId} (${followerCount} followers)`);' || failures=$((failures + 1))
check_literal "Author denorm logunda postId dump'i geri gelmedi" 'console.log(`[AuthorDenorm] Post ${context.params.postId} author alanları güncellendi`);' || failures=$((failures + 1))
check_literal "Author denorm logunda uid dump'i geri gelmedi" '`${uid} profil değişikliği' || failures=$((failures + 1))
check_literal "Email verify warning logunda uid dump'i geri gelmedi" "uid: caller.uid," || failures=$((failures + 1))
check_literal "Current user cache logunda nickname dump'i geri gelmedi" "print('✅ User loaded from cache: \${user.nickname}');" || failures=$((failures + 1))
check_literal "Current user persist logunda nickname dump'i geri gelmedi" "print('💾 User cached: \${user.nickname}');" || failures=$((failures + 1))
check_literal "Story save logunda storyId dump'i geri gelmedi" 'print("Story kaydedildi: $storyId (${serialized.length} element)");' || failures=$((failures + 1))
check_literal "Dispose loglarinda docID dump'i geri gelmedi" 'print("Disposed AgendaContentController for $docID");' || failures=$((failures + 1))
check_literal "Flood error logunda rootID dump'i geri gelmedi" "print('🔥 Kök flood alınamadı: \$rootID – \$e');" || failures=$((failures + 1))
check_literal "Flood error logunda docID dump'i geri gelmedi" "print('🔥 Flood verisi alınamadı: \$docID – \$e');" || failures=$((failures + 1))
check_literal "Copy link debug print docID geri gelmedi" "print(widget.model.docID);" || failures=$((failures + 1))
check_literal "Flood listing init docID debug print geri gelmedi" "print(widget.mainModel.docID);" || failures=$((failures + 1))
check_literal "Antreman yorumlarinda ham user data dump'i geri gelmedi" 'log("User data for $userID: $data");' || failures=$((failures + 1))
check_literal "Test soru upload logunda signed URL dump'i geri gelmedi" 'print("Download URL: $downloadUrl");' || failures=$((failures + 1))
check_literal "Cikmis soru sonucunda cevap dump'i geri gelmedi" "print(cevaplar[index]);" || failures=$((failures + 1))
check_literal "Cikmis soru sonucunda secim dump'i geri gelmedi" "print(secim.value);" || failures=$((failures + 1))
check_literal "Solve test basari logunda testID dump'i geri gelmedi" 'print("Yanitlar başarıyla eklendi: $testID");' || failures=$((failures + 1))
check_literal "Past result sayim logunda snapshot uzunlugu dump'i geri gelmedi" 'print("Snapshot docs: ${filtered.length}");' || failures=$((failures + 1))
check_literal "Past result logunda timestamp dump'i geri gelmedi" 'print("Fetched timeStamp: ${timeStamp.value}");' || failures=$((failures + 1))
check_literal "Past result logunda docID dump'i geri gelmedi" 'print("Hiç veri bulunamadı: ${model.docID}");' || failures=$((failures + 1))
check_literal "Create test question ekrani image URL dump'i geri gelmedi" "print(controller.model.img)" || failures=$((failures + 1))
check_literal "Scholarship share logunda shortUrl dump'i geri gelmedi" "print('Sharing: \$shortUrl');" || failures=$((failures + 1))

if [[ "$failures" -gt 0 ]]; then
  echo
  echo "Security regression scan failed with $failures finding(s)."
  exit 1
fi

echo
echo "Security regression scan passed."
