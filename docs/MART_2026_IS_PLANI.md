# TurqApp — Mart 2026 Is Plani (Analiz Tabanli)
**Audit Tarihi:** 2026-03-26  
**Durum:** Kanonik Mart plani  
**Bu dokuman neyi degistirir:** 2026-03-03 tarihli benchmark/Instagram seviyesi odakli eski planin yerine, kod analizi temelli ve degisim tipi bazli gercek oncelik sirasini koyar.

---

## 0. Dokuman Amaci

Bu plan, repo ustunde yapilan kod analizi sonrasinda cikarilan teknik is sirasini kayda gecirir.

Bu planin ozel kurali su:

- once uygulama davranisini ve mimariyi kokten degistirmeyen isler
- sonra kontrollu bug-fix ve kontrat duzeltmeleri
- en son yapisal refactor ve domain ayristirma

Bu dosya bilincli olarak su iki alani kapsam disi birakir:

- `users` migration backlog'u
- burs / scholarship migration backlog'u

Bu iki alan ayri kritik yol olarak ele alinmalidir. Bu dosya, onlar disinda kalan backlog'un Mart ayindaki dogru teknik sirasini tanimlar.

Kaynak gerceklik koddur. Bu dokumandaki her oncelik, kod referansi ile yazilmistir.

---

## 1. Analizden Cikan Ana Karar

Kod tabani su anda ayni listede hem dusuk riskli kontrat duzeltmeleri hem de yuksek riskli mimari kirilimlar tasiyor.

En buyuk hata, bunlari ayni sprintte ele almak olur.

Mart plani su ilkeye gore uygulanir:

1. Operasyonel risk kapatilir.
2. Admin ve contract akislari netlestirilir.
3. Test bariyeri gercek riskleri olcer hale getirilir.
4. Davranis duzeltmeleri kontrollu ilerler.
5. `Posts`, legacy schema ve domain split gibi yapisal isler Mart'ta coding backlog'una alinmaz; sadece hazirlik notu olarak tutulur.

---

## 2. Mart Ayinda Bilerek Once Yapilmayacak Isler

Asagidaki isler kod tabaninda gercek ama Mart ayinda ilk dalga is degildir:

- `Posts` projection/refactor  
  Dosyalar: [lib/Core/Repositories/post_repository_query_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/post_repository_query_part.dart), [lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart), [functions/src/hybridFeed.ts](/Users/turqapp/Desktop/TurqApp/functions/src/hybridFeed.ts)
- legacy chat/story/question bank schema tasfiyesi  
  Dosyalar: [lib/Core/Repositories/conversation_repository_state_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/conversation_repository_state_part.dart), [lib/Core/Repositories/story_repository.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/story_repository.dart), [lib/Core/Repositories/question_bank_snapshot_repository.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/question_bank_snapshot_repository.dart), [firestore.rules](/Users/turqapp/Desktop/TurqApp/firestore.rules)
- domain split / Pasaj ayristirma  
  Dosyalar: [lib/Modules/Education/pasaj_tabs.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Education/pasaj_tabs.dart), [lib/Core/Repositories/job_repository.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/job_repository.dart), [lib/Core/Repositories/market_repository.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/market_repository.dart), [lib/Core/Repositories/tutoring_repository_query_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/tutoring_repository_query_part.dart)

Sebep:

- bunlar koklu veri akisi veya mimari sinir degisimi uretiyor
- Mart onceligi bunlar degil
- once dusuk riskli backlog temizlenmeden acilmamalilar

---

## 3. Mart Oncelik Merdiveni

### Band A — Davranista ve Mimaride Koklu Degisiklik Yapmayanlar

Bu band Mart ayinin ilk yarisi icin ana coding backlog'dur.

#### A1. Secret cleanup ve leak guard
**Amac:** Repo icindeki service-account leak riskini sifira indirmek.  
**Dosyalar:** [burs-city-firebase-adminsdk-fbsvc-c6d03fc771.json](/Users/turqapp/Desktop/TurqApp/burs-city-firebase-adminsdk-fbsvc-c6d03fc771.json), [turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json](/Users/turqapp/Desktop/TurqApp/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json), [scripts/set_admob_reklam_config.mjs](/Users/turqapp/Desktop/TurqApp/scripts/set_admob_reklam_config.mjs), [scripts/check_repo_security_regressions.sh](/Users/turqapp/Desktop/TurqApp/scripts/check_repo_security_regressions.sh)  
**Yapilacak:** key rotate, repo temizligi, script default key path kaldirma, guard fail kriteri kalici hale getirme.  
**Kabul Kriteri:** repo icinde aktif private key yok, guard service-account pattern'lerini fail ediyor.  
**Risk:** sadece operasyonel; uygulama davranisini degistirmez.  
**Status:** guard tarafi kodda sertlestirildi, operasyonel cleanup halen gerekli.

#### A2. HLS comment/code kontrat temizligi
**Amac:** yorumun soyledigi ile backend matcher'in yaptigi isi ayni hale getirmek.  
**Dosya:** [functions/src/hlsTranscode.ts](/Users/turqapp/Desktop/TurqApp/functions/src/hlsTranscode.ts)  
**Yapilacak:** chat HLS destekleniyorsa matcher'a ekle; desteklenmiyorsa yorumu daralt.  
**Kabul Kriteri:** dosya, kapsam konusunda yanlis bir vaat icermiyor.  
**Risk:** sadece kontrat netligi; runtime degisimi zorunlu degil.

#### A3. Report restore simetrisi
**Amac:** admin review akisinin post ve market icin tutarli olmasi.  
**Dosyalar:** [functions/src/24_reports.ts](/Users/turqapp/Desktop/TurqApp/functions/src/24_reports.ts), [lib/Modules/Profile/Settings/reports_admin_view.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/Settings/reports_admin_view.dart)  
**Yapilacak:** restore / keep-hidden mantigini market tarafinda da netlestirmek, admin UI beklentisini dosyayla uyumlu hale getirmek.  
**Kabul Kriteri:** auto-hide edilen market kaydi admin aksiyonu ile deterministik restore veya confirmed-hidden state'e gider.  
**Risk:** son kullanici mimarisini degistirmez; admin akis duzeltmesidir.  
**Status:** backend simetri kismi kodda duzeltildi; fonksiyonel dogrulama backlog'da kalir.

#### A4. Release gate ve test bariyerini gercek riske cekmek
**Amac:** playback agirlikli sahte guveni azaltmak.  
**Dosyalar:** [scripts/run_release_gate_checks.sh](/Users/turqapp/Desktop/TurqApp/scripts/run_release_gate_checks.sh), [config/test_suites/release_gate_e2e.txt](/Users/turqapp/Desktop/TurqApp/config/test_suites/release_gate_e2e.txt), [functions/tests/rules/firestore.rules.test.js](/Users/turqapp/Desktop/TurqApp/functions/tests/rules/firestore.rules.test.js)  
**Yapilacak:** release-blocking suite'e contract ve rules senaryolari eklemek, sadece playback smokelara guvenmemek.  
**Kabul Kriteri:** release gate app riskini daha gercekci olcer.  
**Risk:** runtime davranisi degismez; sadece kalite kapisi degisir.

---

### Band B — Kontrollu Davranis Degisikligi Yapanlar, Ama Mimariyi Kokten Oynatmayanlar

Bu band Mart ayinin ikinci yarisi icin uygundur.

#### B1. Author/profile sync icin tek authoritative yol secmek
**Amac:** ayni isi iki function'in farkli limit ve mantikla yapmasini bitirmek.  
**Dosyalar:** [functions/src/09_userProfile.ts](/Users/turqapp/Desktop/TurqApp/functions/src/09_userProfile.ts), [functions/src/authorDenorm.ts](/Users/turqapp/Desktop/TurqApp/functions/src/authorDenorm.ts)  
**Yapilacak:** tek ana yol secilecek, digeri read-only yardimci veya tamamen kaldirilacak.  
**Kabul Kriteri:** profile degisikligi sonrasi author alanlari tek backend akisa bagli.  
**Risk:** veri tutarliligi degisir; ama mimari sinir hala ayni kalir.

#### B2. iOS / Android playback parity
**Amac:** ayni Dart kontratinin iki platformda da ayni calismasi.  
**Dosyalar:** [lib/hls_player/hls_controller_playback_part.dart](/Users/turqapp/Desktop/TurqApp/lib/hls_player/hls_controller_playback_part.dart), [ios/Runner/HLSPlayerPlugin.swift](/Users/turqapp/Desktop/TurqApp/ios/Runner/HLSPlayerPlugin.swift), [ios/Runner/HLSPlayerView.swift](/Users/turqapp/Desktop/TurqApp/ios/Runner/HLSPlayerView.swift), [android/app/src/main/kotlin/com/turqapp/app/ExoPlayerPlugin.kt](/Users/turqapp/Desktop/TurqApp/android/app/src/main/kotlin/com/turqapp/app/ExoPlayerPlugin.kt)  
**Yapilacak:** `loadVideo(url, autoPlay, loop)` parametrelerinin her iki platformda da ayni uygulanmasi, parity smoke eklenmesi.  
**Kabul Kriteri:** ayni method-channel cagrisi platforma gore farkli davranmiyor.  
**Risk:** runtime davranisi degisir ama bu bug-fix seviyesindedir.  
**Status:** iOS runtime parametre aktarimi kodda duzeltildi; tam derleme dogrulamasi ortam bagimliliklari nedeniyle acik.

#### B3. Startup init zincirini `critical` / `best-effort` diye ayirmak
**Amac:** sessiz bozulmayi azaltmak.  
**Dosyalar:** [lib/main.dart](/Users/turqapp/Desktop/TurqApp/lib/main.dart), [lib/Modules/Splash/splash_view_startup_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Splash/splash_view_startup_part.dart), [lib/Modules/NavBar/nav_bar_view.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/NavBar/nav_bar_view.dart)  
**Yapilacak:** kritik init adimlari hata aldiginda degrade-state veya fail-fast; opsiyonel warmup'lar best-effort kalacak.  
**Kabul Kriteri:** startup'ta sessizce yutulup yarim acilan uygulama akislari azalir.  
**Risk:** hata anindaki kullanici deneyimi degisir; mimari komple yeniden yazilmaz.

#### B4. Notification payload ve rate limiter sertlestirmesi
**Amac:** gevsek payload ve instance-memory tabanli abuse savunmasini toparlamak.  
**Dosyalar:** [functions/src/notificationInbox.ts](/Users/turqapp/Desktop/TurqApp/functions/src/notificationInbox.ts), [functions/src/notificationPushPolicy.ts](/Users/turqapp/Desktop/TurqApp/functions/src/notificationPushPolicy.ts), [functions/src/index.ts](/Users/turqapp/Desktop/TurqApp/functions/src/index.ts), [functions/src/rateLimiter.ts](/Users/turqapp/Desktop/TurqApp/functions/src/rateLimiter.ts)  
**Yapilacak:** payload alanlarini daraltmak, abuse riski yuksek call'larda daha guclu limit dusunmek.  
**Kabul Kriteri:** inbox/push kontrati daha tipli, rate limit daha acik tanimli.  
**Risk:** gercek davranis degisimi var; ama domain veya veri modeli tamamen yeniden cizilmez.

---

### Band C — Mart'ta Coding Olarak Acilmamasi Gereken Koklu Isler

Bu band backlog olarak dokumanda kalir ama aktif sprint isine donusmez.

#### C1. `Posts` projection ve sosyal veri modeli ayristirma
**Dosyalar:** [lib/Core/Repositories/post_repository_query_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/post_repository_query_part.dart), [lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart), [lib/Core/Repositories/short_repository_query_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/short_repository_query_part.dart), [lib/Core/Repositories/explore_repository_query_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/explore_repository_query_part.dart), [functions/src/hybridFeed.ts](/Users/turqapp/Desktop/TurqApp/functions/src/hybridFeed.ts)  
**Sebep:** koklu veri akisi degisimi.

#### C2. Legacy schema tasfiyesi
**Dosyalar:** [lib/Core/Repositories/conversation_repository_state_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/conversation_repository_state_part.dart), [lib/Core/Repositories/conversation_repository_message_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/conversation_repository_message_part.dart), [lib/Core/Repositories/story_repository.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/story_repository.dart), [lib/Core/Repositories/question_bank_snapshot_repository.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/question_bank_snapshot_repository.dart), [firestore.rules](/Users/turqapp/Desktop/TurqApp/firestore.rules)  
**Sebep:** migration ve read/write compatibility gerektirir.

#### C3. Domain split / Pasaj ayristirma
**Dosyalar:** [lib/Modules/Education/pasaj_tabs.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Education/pasaj_tabs.dart), [lib/Core/Repositories/job_repository.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/job_repository.dart), [lib/Core/Repositories/market_repository.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/market_repository.dart), [lib/Core/Repositories/tutoring_repository_query_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/tutoring_repository_query_part.dart)  
**Sebep:** bu artik duzeltme degil, urun/mimari yeniden cizimidir.

---

## 4. Mart Sprint Dagilimi

### Sprint M1 — Dusuk Riskli Temizlik ve Kontrat Netlestirme

Hedef:

- A1 tamamlanir
- A2 tamamlanir
- A3 fonksiyonel olarak dogrulanir
- A4 backlog'u aktif hale getirilir

Sprint cikisi:

- repo secret hygiene konusunda korunur
- HLS backend kapsaminda yanlis vaat kalmaz
- report admin akisi tutarsiz kalmaz
- test bariyeri hangi riskleri olctugunu daha net soyler

### Sprint M2 — Kontrollu Bug-Fix Dalgasi

Hedef:

- B1 ownership karari cikar
- B2 parity smoke ile birlikte kapanir
- B3 icin kritik init matrisi olusur
- B4 icin notification/rate limit contract'i yazilir

Sprint cikisi:

- platformlar arasi farklar azalir
- duplicate backend ownership alanlari azalir
- startup akisinda sessiz bozulma noktasi envanteri kapanir

### Sprint M3 — Yapisal Isler Icin Karar Sprinti, Coding Degil

Hedef:

- C1, C2, C3 icin sadece karar dokumani ve dependency haritasi hazirlanir
- kod degisikligi acilmaz

Sprint cikisi:

- yapisal backlog acik ama kontrol altinda olur
- Mart ayinda yanlislikla buyuk refactor baslatilmaz

---

## 5. Kabul Kurallari

Bu plan uygulanirken su kurallar korunur:

1. Band A bitmeden Band B acilmaz.
2. Band B bitmeden Band C coding olarak baslatilmaz.
3. Release gate duzeltilmeden parity ve startup gibi davranis degistiren isler kapatilmis sayilmaz.
4. Kod analiziyle celisen eski plan ciktisi dogru kabul edilmez.

---

## 6. Mart Sonu Basari Tanimi

Mart sonunda bu plan basarili sayilacaksa en az su durum gorulmeli:

- repo secret hygiene kontrol altinda
- HLS / report / test kontratlari daha net
- iOS ve Android playback kontrati ayni
- duplicate backend ownership alanlari daralmis
- startup'taki sessiz bozulma noktalarinin listesi kapanmis
- yapisal buyuk isler mart coding backlog'una acilmamis

Bu basari tanimi bilerek muhafazakardir.

Mart hedefi sistemi yeniden yazmak degil, rastgele refactor'a gitmeden riskli ama dusuk etkili kiriklari temizlemektir.

---

## 7. Bu Dokumanin Kaynagi

Bu dokuman asagidaki analiz basliklarindan turetilmistir:

- sert bulgular
- gercek mimari
- moduller arasi coupling
- backend contract analizi
- playback / native hat analizi
- test sistemi gercekligi

Bu nedenle bu dokuman bir fikir listesi degil; repo koduna dayali oncelik sirasi dokumanidir.

