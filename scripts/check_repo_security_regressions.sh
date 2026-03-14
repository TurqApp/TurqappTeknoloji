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

check_literal_in_file() {
  local label="$1"
  local pattern="$2"
  local file="$3"

  if rg -n --fixed-strings "$pattern" "$file"; then
    echo
    echo "[FAIL] $label"
    return 1
  fi

  echo "[PASS] $label"
  return 0
}

check_context_literal_in_file() {
  local label="$1"
  local anchor="$2"
  local forbidden="$3"
  local file="$4"

  if rg -n -C 6 --fixed-strings "$anchor" "$file" | rg -n --fixed-strings "$forbidden"; then
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
check_literal "Cikmis soru yil seciminde ana baslik debug dump'i geri gelmedi" 'print("DEVELOPER ${widget.anaBaslik}");' || failures=$((failures + 1))
check_literal "Cikmis soru yil seciminde baslik2 debug dump'i geri gelmedi" 'print("DEVELOPER ${widget.baslik2}");' || failures=$((failures + 1))
check_literal "Cikmis soru yil seciminde baslik3 debug dump'i geri gelmedi" 'print("DEVELOPER ${widget.baslik3}");' || failures=$((failures + 1))
check_literal_in_file "Answer key controller kitapcik sayisi debug logu geri gelmedi" 'log("Çekilen kitapçık sayısı: ${bookList.length}");' "lib/Modules/Education/AnswerKey/answer_key_controller.dart" || failures=$((failures + 1))
check_literal_in_file "Answer key controller fetch hata logu geri gelmedi" 'log("Veri çekme hatası: $e");' "lib/Modules/Education/AnswerKey/answer_key_controller.dart" || failures=$((failures + 1))
check_literal_in_file "Answer key controller loadMore hata logu geri gelmedi" 'log("AnswerKeyController.loadMore error: $e");' "lib/Modules/Education/AnswerKey/answer_key_controller.dart" || failures=$((failures + 1))
check_literal_in_file "Answer key typesense hata logu geri gelmedi" 'log("Answer key typesense search error: $e");' "lib/Modules/Education/AnswerKey/answer_key_controller.dart" || failures=$((failures + 1))
check_literal "Category answer key hata dump'i geri gelmedi" 'print("Error fetching booklets: $e");' || failures=$((failures + 1))
check_literal "My test results hata dump'i geri gelmedi" 'print("Error fetching test results: $e");' || failures=$((failures + 1))
check_literal "Saved tests hata dump'i geri gelmedi" 'print("Error fetching saved tests: $e");' || failures=$((failures + 1))
check_literal "Optical form delete hata dump'i geri gelmedi" 'print("Error deleting optical form: $e");' || failures=$((failures + 1))
check_literal "Test entry success debug print geri gelmedi" 'print("buldu");' || failures=$((failures + 1))
check_literal "Test entry miss debug print geri gelmedi" 'print("veriyok");' || failures=$((failures + 1))
check_literal "Test entry error dump'i geri gelmedi" 'print("Error fetching test: $e");' || failures=$((failures + 1))
check_literal_in_file "Solve test fetch question error dump'i geri gelmedi" 'print("Error fetching questions: $e");' "lib/Modules/Education/Tests/SolveTest/solve_test_controller.dart" || failures=$((failures + 1))
check_literal "Solve test user data error dump'i geri gelmedi" 'print("Error fetching user data: $e");' || failures=$((failures + 1))
check_literal "Solve test submit error dump'i geri gelmedi" 'print("Yanitlar eklenirken hata: $error");' || failures=$((failures + 1))
check_literal "Scholarship detail apply status debug print geri gelmedi" "print('Başvuru durumu kontrol ediliyor');" || failures=$((failures + 1))
check_literal "Scholarship detail type debug print geri gelmedi" "print('Burs başvuru tipi: \$type');" || failures=$((failures + 1))
check_literal "Scholarship detail apply state dump'i geri gelmedi" "print('Son başvuru durumu: \${allreadyApplied.value}');" || failures=$((failures + 1))
check_literal "Scholarship detail invalid id debug print geri gelmedi" "print('Geçersiz burs ID');" || failures=$((failures + 1))
check_literal "Scholarship detail error dump'i geri gelmedi" "print('Başvuru durumu kontrol edilirken hata: \$e');" || failures=$((failures + 1))
check_literal "Scholarship detail apply save error dump'i geri gelmedi" "print('Başvuru kaydedilirken hata: \$e');" || failures=$((failures + 1))
check_literal "Scholarship detail page index debug print geri gelmedi" "print('Güncellenen sayfa indeksi: \$pageIndex');" || failures=$((failures + 1))
check_literal "Scholarship detail follow error dump'i geri gelmedi" 'print("Takip işlemi hatası: $e");' || failures=$((failures + 1))
check_literal "Scholarship detail delete debug print geri gelmedi" 'print("deleteScholarship hatası.");' || failures=$((failures + 1))
check_literal "Scholarship detail cancel error dump'i geri gelmedi" "print('Başvuru iptal edilirken hata: \$e');" || failures=$((failures + 1))
check_literal "Past test results preview hata dump'i geri gelmedi" 'print("Error fetching test results: $e");' || failures=$((failures + 1))
check_literal "My tests hata dump'i geri gelmedi" 'print("Error fetching tests: $e");' || failures=$((failures + 1))
check_literal "Test past result count hata dump'i geri gelmedi" 'print("Error fetching answer count: $e");' || failures=$((failures + 1))
check_literal_in_file "My booklet results fetch hata logu geri gelmedi" 'log("fetchBookletResults error: $e");' "lib/Modules/Education/AnswerKey/MyBookletResults/my_booklet_results_controller.dart" || failures=$((failures + 1))
check_literal_in_file "My booklet results optik sonuc hata logu geri gelmedi" 'log("fetchOptikSonuclari error: $error");' "lib/Modules/Education/AnswerKey/MyBookletResults/my_booklet_results_controller.dart" || failures=$((failures + 1))
check_literal_in_file "Saved optical forms hata logu geri gelmedi" 'log("SavedOpticalFormsController.getData error: $e");' "lib/Modules/Education/AnswerKey/SavedOpticalForms/saved_optical_forms_controller.dart" || failures=$((failures + 1))
check_literal_in_file "Optical preview baglanti debug print'i geri gelmedi" '? "İnternet bağlantısı var."' "lib/Modules/Education/AnswerKey/OpticalPreview/optical_preview_controller.dart" || failures=$((failures + 1))
check_literal "Solve test basari logunda testID dump'i geri gelmedi" 'print("Yanitlar başarıyla eklendi: $testID");' || failures=$((failures + 1))
check_literal "Past result sayim logunda snapshot uzunlugu dump'i geri gelmedi" 'print("Snapshot docs: ${filtered.length}");' || failures=$((failures + 1))
check_literal "Past result logunda timestamp dump'i geri gelmedi" 'print("Fetched timeStamp: ${timeStamp.value}");' || failures=$((failures + 1))
check_literal "Past result logunda docID dump'i geri gelmedi" 'print("Hiç veri bulunamadı: ${model.docID}");' || failures=$((failures + 1))
check_literal "Create test question ekrani image URL dump'i geri gelmedi" "print(controller.model.img)" || failures=$((failures + 1))
check_literal "Scholarship share logunda shortUrl dump'i geri gelmedi" "print('Sharing: \$shortUrl');" || failures=$((failures + 1))
check_literal "Booklet answer logunda reklam unit dump'i geri gelmedi" 'log("GOOGLE ADMOB RANDOM ID: $adUnitId");' || failures=$((failures + 1))
check_literal "Booklet answer logunda sonuc dump'i geri gelmedi" 'log("Doğru: $correct, Yanlış: $wrong, Puan: $score");' || failures=$((failures + 1))
check_literal_in_file "Booklet answer reklam fetch hata logu geri gelmedi" 'log("Reklam verisi çekme hatası: $e");' "lib/Modules/Education/AnswerKey/BookletAnswer/booklet_answer_controller.dart" || failures=$((failures + 1))
check_literal_in_file "Booklet answer sonuc kaydetme hata logu geri gelmedi" 'log("Test sonucu kaydetme hatası: $e");' "lib/Modules/Education/AnswerKey/BookletAnswer/booklet_answer_controller.dart" || failures=$((failures + 1))
check_literal "Answer key content logunda docID ve nickname dump'i geri gelmedi" 'log("Kullanıcı verisi çekildi: ${model.docID} için nickname: ${nickname.value}",' || failures=$((failures + 1))
check_literal "Booklet preview logunda cevap anahtari listesi dump'i geri gelmedi" 'log("Çekilen cevap anahtarları: ${newList.map((e) => e.baslik).toList()}",' || failures=$((failures + 1))
check_literal_in_file "Booklet preview save state hata logu geri gelmedi" 'log("Kaydet durumu okunamadı: $e");' "lib/Modules/Education/AnswerKey/BookletPreview/booklet_preview_controller.dart" || failures=$((failures + 1))
check_literal_in_file "Booklet preview answer key fetch hata logu geri gelmedi" 'log("Cevap anahtarlarını çekme hatası: $e");' "lib/Modules/Education/AnswerKey/BookletPreview/booklet_preview_controller.dart" || failures=$((failures + 1))
check_literal_in_file "Booklet preview user data hata logu geri gelmedi" 'log("Kullanıcı verisi çekme hatası: $e");' "lib/Modules/Education/AnswerKey/BookletPreview/booklet_preview_controller.dart" || failures=$((failures + 1))
check_literal_in_file "Booklet preview bookmark hata logu geri gelmedi" 'log("Yer işareti değiştirme hatası: $e");' "lib/Modules/Education/AnswerKey/BookletPreview/booklet_preview_controller.dart" || failures=$((failures + 1))
check_literal "Upload queue image logunda dosya adi dump'i geri gelmedi" "\${p.basename(imagePath)}" || failures=$((failures + 1))
check_literal "Upload queue preflight logunda path dump'i geri gelmedi" "path=\${ref.fullPath}" || failures=$((failures + 1))
check_literal "Upload queue preflight logunda uid dump'i geri gelmedi" "uid=\$userID" || failures=$((failures + 1))
check_literal "Upload queue preflight logunda post owner dump'i geri gelmedi" "postUserID=" || failures=$((failures + 1))
check_literal "Upload queue video logunda URL dump'i geri gelmedi" "MB url=\$videoUrl" || failures=$((failures + 1))
check_literal "Upload queue thumbnail logunda URL dump'i geri gelmedi" "url=\$thumbnailUrl" || failures=$((failures + 1))
check_literal "WebP preflight logunda path uid dump'i geri gelmedi" "[UploadPreflight][WebP] path=\${ref.fullPath} uid=\$uid bytes=\${data.length}" || failures=$((failures + 1))
check_literal_in_file "Post shell preflight logunda docID dump'i geri gelmedi" "docID=\$docID " "lib/Modules/PostCreator/post_creator_controller_upload_support.dart" || failures=$((failures + 1))
check_literal_in_file "Post shell preflight logunda uid dump'i geri gelmedi" "uid=\$uid " "lib/Modules/PostCreator/post_creator_controller_upload_support.dart" || failures=$((failures + 1))
check_literal_in_file "Post shell preflight logunda server user dump'i geri gelmedi" "serverUserID=\$shellUserId" "lib/Modules/PostCreator/post_creator_controller_upload_support.dart" || failures=$((failures + 1))
check_literal "Post creator image preflight logunda path uid dump'i geri gelmedi" 'path=Posts/$docID/image_$j.webp' || failures=$((failures + 1))
check_literal "Post creator image preflight logunda post owner dump'i geri gelmedi" 'postUserID=${postDoc?["userID"]}' || failures=$((failures + 1))
check_literal "Post creator video preflight logunda path dump'i geri gelmedi" 'path=${videoRef.fullPath}' || failures=$((failures + 1))
check_literal "Post creator thumbnail logunda URL dump'i geri gelmedi" "url=\$thumbnailUrl" || failures=$((failures + 1))
check_literal "Quote publish direct logunda docID dump'i geri gelmedi" '[QuotePublish/direct] docID=$docID quoted=$_isQuotedPost original=$_sharedOriginalPostID source=$_sharedSourcePostID user=$currentUserId' || failures=$((failures + 1))
check_literal "Quote publish direct-alt logunda docID dump'i geri gelmedi" '[QuotePublish/direct-alt] docID=$docID quoted=$_isQuotedPost original=$_sharedOriginalPostID source=$_sharedSourcePostID user=$currentUserId' || failures=$((failures + 1))
check_literal "Post like search logunda query dump'i geri gelmedi" 'query=\"$normalized\"' || failures=$((failures + 1))
check_literal "Post like search logunda term dump'i geri gelmedi" 'term=\"$term\"' || failures=$((failures + 1))
check_literal "Tag posts logunda tag dump'i geri gelmedi" 'print(">>> Tag post araması başlıyor! [TAG: $tag]")' || failures=$((failures + 1))
check_literal "Tag posts logunda sonuc dump'i geri gelmedi" 'print(">>> Tag sonuç: ${fetchedPosts.length}")' || failures=$((failures + 1))
check_literal_in_file "Agenda ilk video trigger logunda docID dump'i geri gelmedi" "print('🎬 İlk video manuel trigger: \${firstPost.docID}');" "lib/Modules/Agenda/agenda_controller.dart" || failures=$((failures + 1))
check_literal "Deleted stories controller logunda uid dump'i geri gelmedi" 'DeletedStoriesController.fetch: uid=$uid' || failures=$((failures + 1))
check_literal "Deleted stories repository logunda uid dump'i geri gelmedi" 'Deleted stories fetch: uid=$uid' || failures=$((failures + 1))
check_literal "Mandatory follow logunda uid dump'i geri gelmedi" '[MandatoryFollow] follow failed uid=$uid' || failures=$((failures + 1))
check_literal "Reshare helper post owner dump'i geri gelmedi" "print('  postUserID: \$postUserID');" || failures=$((failures + 1))
check_literal "Reshare helper original owner dump'i geri gelmedi" "print('  existingOriginalUserID: \$existingOriginalUserID');" || failures=$((failures + 1))
check_literal "Reshare helper original post dump'i geri gelmedi" "print('  existingOriginalPostID: \$existingOriginalPostID');" || failures=$((failures + 1))
check_literal "Reshare helper current post dump'i geri gelmedi" "print('  currentPostID: \$currentPostID');" || failures=$((failures + 1))
check_literal "Reshare helper current user dump'i geri gelmedi" "print('  currentUserID: \$currentUserID');" || failures=$((failures + 1))
check_literal "User profile sync logunda userId dump'i geri gelmedi" '[User Profile Sync] Started for user: ${userId}' || failures=$((failures + 1))
check_literal "User profile sync missing snapshot logunda userId dump'i geri gelmedi" '[User Profile Sync] Missing before/after snapshot for user: ${userId}' || failures=$((failures + 1))
check_literal "User profile sync skip logunda userId dump'i geri gelmedi" '[User Profile Sync] No displayable fields changed. Skipping sync for user: ${userId}' || failures=$((failures + 1))
check_literal "User profile sync no posts logunda userId dump'i geri gelmedi" '[User Profile Sync] No posts found for user: ${userId}' || failures=$((failures + 1))
check_literal "User profile sync no posts responseunda userId dump'i geri gelmedi" 'No posts found for user: ${userId}' || failures=$((failures + 1))
check_literal "User profile sync fail logunda userId dump'i geri gelmedi" '[User Profile Sync] Failed for user: ${userId}' || failures=$((failures + 1))
check_literal "Manual sync fail logunda userId dump'i geri gelmedi" '[Manual Sync] Failed for user: ${userId}' || failures=$((failures + 1))
check_literal "Hybrid feed create logunda postId dump'i geri gelmedi" '[HybridFeed] Fan-out complete: ${postId}' || failures=$((failures + 1))
check_literal "Hybrid feed delete logunda postId dump'i geri gelmedi" '[HybridFeed] Post ${postId} feed items cleaned up' || failures=$((failures + 1))
check_literal "Hybrid feed follower logunda followerId dump'i geri gelmedi" '[HybridFeed] Backfilled ${postsSnap.size} posts for new follower ${followerId}' || failures=$((failures + 1))
check_literal "HLS processing logunda target id dump'i geri gelmedi" '[HLS] Processing video for ${target.type}: ${target.id}' || failures=$((failures + 1))
check_literal "HLS complete logunda URL dump'i geri gelmedi" '[HLS] Complete for ${target.type}:${target.id}. HLS URL: ${hlsUrl}' || failures=$((failures + 1))
check_literal "HLS story delete logunda path dump'i geri gelmedi" '[HLS] Story source deleted: ${filePath}' || failures=$((failures + 1))
check_literal "HLS error logunda target id dump'i geri gelmedi" '[HLS] Error processing ${target.type}:${target.id}:' || failures=$((failures + 1))
check_literal "Tutoring notification logunda tutor/doc dump'i geri gelmedi" '[TutoringNotif] Application notification sent to ${tutorUID} for ${docId}' || failures=$((failures + 1))
check_literal "Tutoring notification status logunda applicant dump'i geri gelmedi" '[TutoringNotif] Status update notification sent to ${applicantId}: ${newStatus}' || failures=$((failures + 1))
check_literal "Thumbnail skip logunda filePath dump'i geri gelmedi" 'Already a thumbnail, skipping:' || failures=$((failures + 1))
check_literal "Thumbnail avatar skip logunda filePath dump'i geri gelmedi" 'Profile avatar source file, skipping thumbnail generation:' || failures=$((failures + 1))
check_literal "Thumbnail non-image logunda filePath dump'i geri gelmedi" 'Not an image file, skipping:' || failures=$((failures + 1))
check_literal "Thumbnail temp download logunda path dump'i geri gelmedi" 'Downloaded to temp:' || failures=$((failures + 1))
check_literal "Thumbnail small image logunda filePath dump'i geri gelmedi" 'Image is already <= 600px, skipping thumbnail generation:' || failures=$((failures + 1))
check_literal "Thumbnail generation logunda temp path dump'i geri gelmedi" 'Generated ${width}px thumbnail:' || failures=$((failures + 1))
check_literal "Thumbnail upload logunda storage path dump'i geri gelmedi" 'Uploaded thumbnail to:' || failures=$((failures + 1))
check_literal "Thumbnail cleanup logunda temp path dump'i geri gelmedi" 'Cleaned up temp file:' || failures=$((failures + 1))
check_literal "Thumbnail complete logunda filePath dump'i geri gelmedi" '✅ Thumbnail generation complete for: ${filePath}' || failures=$((failures + 1))
check_literal "Shared post cascade logunda source post id dump'i geri gelmedi" '[cascadeDeleteSharedPosts] source=${postId}' || failures=$((failures + 1))
check_literal "Backfill posts logunda doc id dump'i geri gelmedi" "console.error('backfillPostsOriginalFields: error on', doc.id, e);" || failures=$((failures + 1))
check_literal "countDocuments logunda collection path dump'i geri gelmedi" 'console.error("countDocuments error", collection.path, err);' || failures=$((failures + 1))
check_literal "purge post logunda docPath dump'i geri gelmedi" 'console.error("purgePostSubcollections error", docPath, error);' || failures=$((failures + 1))
check_literal "purge student logunda docPath dump'i geri gelmedi" "console.error('purgeStudentSubcollections error', docPath, name, err);" || failures=$((failures + 1))
check_literal "purge student fatal logunda docPath dump'i geri gelmedi" "console.error('purgeStudentSubcollections fatal error', docPath, err);" || failures=$((failures + 1))
check_context_literal_in_file "Password reset SMS logunda email dump'i geri gelmedi" 'console.error("sendPasswordResetSmsCode netgsm-error", {' "emailLower," "functions/src/11_resend.ts" || failures=$((failures + 1))
check_context_literal_in_file "Password reset SMS logunda uid dump'i geri gelmedi" 'console.error("sendPasswordResetSmsCode netgsm-error", {' "uid," "functions/src/11_resend.ts" || failures=$((failures + 1))
check_context_literal_in_file "Password reset SMS logunda sağlayici body dump'i geri gelmedi" 'console.error("sendPasswordResetSmsCode netgsm-error", {' "netgsmBody," "functions/src/11_resend.ts" || failures=$((failures + 1))
check_context_literal_in_file "Signup SMS logunda phone dump'i geri gelmedi" 'console.error("sendSignupSmsCode netgsm-error", {' "phone," "functions/src/11_resend.ts" || failures=$((failures + 1))
check_context_literal_in_file "Password reset SMS logunda email dump'i lib tarafinda geri gelmedi" 'console.error("sendPasswordResetSmsCode netgsm-error", {' "emailLower," "functions/lib/11_resend.js" || failures=$((failures + 1))
check_context_literal_in_file "Password reset SMS logunda uid dump'i lib tarafinda geri gelmedi" 'console.error("sendPasswordResetSmsCode netgsm-error", {' "uid," "functions/lib/11_resend.js" || failures=$((failures + 1))
check_context_literal_in_file "Password reset SMS logunda sağlayici body dump'i lib tarafinda geri gelmedi" 'console.error("sendPasswordResetSmsCode netgsm-error", {' "netgsmBody," "functions/lib/11_resend.js" || failures=$((failures + 1))
check_context_literal_in_file "Signup SMS logunda phone dump'i lib tarafinda geri gelmedi" 'console.error("sendSignupSmsCode netgsm-error", {' "phone," "functions/lib/11_resend.js" || failures=$((failures + 1))

if [[ "$failures" -gt 0 ]]; then
  echo
  echo "Security regression scan failed with $failures finding(s)."
  exit 1
fi

echo
echo "Security regression scan passed."
