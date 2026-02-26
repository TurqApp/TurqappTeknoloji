# TurqApp Codex Handover (2026-02-26)

## 1) Kilit Durum Özeti
- iOS release build tarafında Xcode aşamasında takılma ("Running Xcode build...") periyodik olarak tekrar ediyor.
- Android debug run çalışıyor.
- iOS debug/release koşusu, signing/capability ve Xcode build lock/cache konularından etkileniyor.
- Short link altyapısı (Cloudflare Worker + KV + Firebase function resolve) devrede; bazı link çözümleme sorunları case-sensitivity kaynaklı düzeltilmişti.

## 2) Yapılmış Kritik Teknik Değişiklikler

### 2.1 Short Link / Deep Link / Share
- Kısa link üretme ve paylaşım akışı post/short/profile taraflarına bağlandı.
- `resolveShortLink` fonksiyonunda case-sensitive id çözümleme düzeltildi (özellikle post/story için).
- Deep link parse/fallback iyileştirildi.
- Paylaşımda üst üste sheet açılmasını engellemek için share guard eklendi.

### 2.2 Crashlytics / dSYM
- iOS proje script phase tarafında Crashlytics symbol upload daha sağlam akışa çekildi.
- Manuel upload denemeleri yapıldı, yeni buildler için otomatik upload altyapısı güncellendi.
- Eski "Missing dSYM" uyarılarının bir kısmı geçmiş build UUID mismatch kaynaklı kalabilir.

### 2.3 Chat / Mesaj Akışı
- Sohbet listesi ve mesaj ekranında çok sayıda UX/akış güncellemesi yapıldı (okunmadı, arşiv davranışları, yanıt kartları vb.).
- Bazı davranışlar halen canlı testte tekrar doğrulama gerektiriyor (özellikle uzun bas menü/yanıt kartı pixel-level beklentiler).

### 2.4 iOS Build Stabilitesi
- DerivedData / XCBuildData lock temizliği defalarca uygulandı.
- Pod install tekrarlandı.
- `video_thumbnail` kaynaklı Xcode 26 uyumluluk hataları için Podfile düzeltmesi yapıldı.
- Buna rağmen release build bazı denemelerde sessiz takılma davranışı verdi.

## 3) Şu An Önceliklendirilmiş Yapılacaklar (P0 -> P3)

## P0 — iOS Build Stabilizasyonu (Önce)
1. Mac reboot sonrası tek süreçle iOS build testi.
2. Xcode içinden tek başına `Product > Build` (Release config) doğrulaması.
3. Ardından terminalden `flutter run --release -d <ios_udid> --no-resident`.
4. Build lock tekrarlarsa:
   - tüm `xcodebuild/flutter_tools` süreçlerini kapat
   - `DerivedData/Runner-*` + `XCBuildData` + `ModuleCache.noindex` temizle
   - tek süreç kuralı ile tekrar çalıştır.

## P1 — Chat Stabilite + UX Tamamlama
1. Mesaj uzun bas menüsü tüm içerik tiplerinde tek davranışla doğrulansın.
2. Yanıt kartı genişliği/balon genişliği kuralları WhatsApp benzeri nihai hale getirilsin.
3. Okunmadı/kalın metin durumları sohbet içi/sohbet dışı geçişte tekrar test edilsin.
4. Sohbet listesinde sabitle/sessize al/okunmadı davranışları backend-state ile tekrar entegre test.

## P2 — Share & Link Akışı Tam Test
1. Post, short, profile, story paylaşım linklerinin tümü kısa link (turqapp.com/p|s|u) doğrulansın.
2. Link preview (OG) WhatsApp/Telegram/X testleri yapılmalı.
3. "Link açılamadı" fallback akışı 3 platformda doğrulanmalı.

## P3 — dSYM Kalan Eski Uyarılar
1. Eski release UUID’leri için matching archive varsa manuel upload.
2. Yeni release sonrası Crashlytics panelinde unresolved UUID kalıp kalmadığını kontrol.

## 4) Cloudflare Shortlink Altyapısı (Durum)
- Worker deploy edildi.
- KV namespace oluşturuldu (`turq-shortlinks-prod`).
- Route yapısı: `/p/*`, `/s/*`, `/u/*`, `/.well-known/*`.
- DNS tarafında kök A ve www CNAME proxied ayarları yapıldı.
- Devam: prod doğrulama (preview/deeplink/fallback) checklist ile tamamlanmalı.

## 5) Kritik Operasyon Notları
- Aynı anda Xcode Run + terminal Flutter Run çalıştırma: build.db lock üretir.
- iOS tarafında test sırasında cihaz ekranı açık olmalı, güven/izin popup’ları anlık onaylanmalı.
- Wireless iOS debug/release daha sık takılıyor; mümkünse USB öncelikli.

## 6) Çalışma Disiplini (Bu projede sabit kural)
- Her büyük değişimden sonra:
  1. `flutter analyze` (etkilenen dosyalar)
  2. Android debug smoke test
  3. iOS smoke test (önce debug, sonra release)
- Tek seferde çok değişiklik yerine küçük blok + doğrulama.

## 7) Son Not
- Bu dosya, uzun konuşma geçmişinin operasyonel özetidir.
- Buradan sonra ilerleme P0 -> P1 -> P2 -> P3 sırasıyla yürütülmelidir.

## 8) Son Oturumda Eklenenler (Kaldığımız Yer)

### 8.1 Typesense / Rozet
- `users_search` şemasına `rozet` alanı eklendi ve mapping bağlandı.
- Tüm kullanıcıların Typesense'e düşmesi için reindex fonksiyonları deploy edildi:
  - `f15_syncUsersToTypesense`
  - `f15_reindexUsersToTypesenseCallable`
  - `f15_reindexUsersToTypesenseScheduled`
  - `f15_searchUsersCallable`

### 8.2 Cloudflare Shortlink
- Worker + KV akışı deploy edildi, route'lar aktif:
  - `/p/*`, `/s/*`, `/u/*`, `/.well-known/*`
- KV namespace:
  - `turq-shortlinks-prod`
- DNS root ve `www` kayıtları proxied.

### 8.3 Android Son Durum
- Android debug run başarılı.
- Son ölçümlerde startup normal aralıkta.
- Loglarda hala story query composite index uyarısı görülebiliyor (bloklayıcı değil).

### 8.4 Bilgisayar Yeniden Başlatma Sonrası Hedef
- Ana hedef: iOS `--release` run takılma sorununu çözmek (P0).
- Kural: aynı anda tek build süreci (Xcode ve terminal paralel build yok).

## 9) Reboot Sonrası Uygulanacak Net Akış (P0)

1. Temiz başlangıç:
   - `flutter clean`
   - `ios/Pods` ve `Podfile.lock` temizlenip `pod install`
2. Xcode'da önce sadece `Release` build doğrulaması (`Product > Build`)
3. Ardından terminalden:
   - `flutter run --release -d <IOS_UDID> --no-resident`
4. Takılma olursa lock reset:
   - `pkill -f xcodebuild`
   - `pkill -f flutter_tools`
   - `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*`
5. Tekrar 2. adımdan devam.

## 10) Bu Sohbete Yeniden Başlama Cümlesi
- `TurqApp release run sorununa devam edelim, kaldığımız yerden P0 adımlarını uygula.`
