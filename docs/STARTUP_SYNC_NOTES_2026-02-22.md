# Startup Sync Notları (22 Şubat 2026)

## Amaç
- Amaç erken açılış değildir.
- Amaç: Splash ekranı kapanmadan önce feed, story, shorts ve temel servislerin hazır olması.
- iOS ve Android açılış akışının aynı sıra ve aynı kriterlerle çalışması.

## Ortak Kurulum Sırası (iOS + Android)
1. `Firebase bootstrap` (runApp sonrası başlatılır, Splash içinde beklenir)
2. `FirestoreConfig.initialize`
3. `CurrentUserService.initialize` + `ilk açılış auth cleanup` + `lockApp check`
4. `GetX dependency registration`
5. `Senkron startup kapısı`:
   - minimum splash süresi
   - minimum startup hazırlığı
   - kritik veri hazır olma kontrolü (feed/story/shorts)
6. `NavDecision` (NavBar / SignIn)
7. Arka plan warm-up işleri (cache proxy, ads, notifications, extended preload)

## Senkron Açılış Kriterleri
- Min splash görünürlük: `1800ms`
- Max kritik bekleme: `6000ms`
- Nav öncesi minimum içerik:
  - Feed: `>= 6 post`
  - Story: `>= 1 kullanıcı`
  - Shorts: `>= 3 video`

## Log Etiketleri
- `[StartupTrace] launch->Splash.initState`
- `[StartupTrace] launch->Splash.firstFrame`
- `[StartupSync] phase=begin`
- `[StartupSync] phase=minimum_ready`
- `[StartupSync] phase=critical_ready`
- `[StartupTrace] launch->NavDecision(...)`
- `⚡ App startup: ...ms`

## Ortak Test Protokolü
- iOS: `flutter run -d 00008030-001E11312E90402E`
- Android: `flutter run -d 192.168.1.189:5555`
- Her iki platformda da aynı log etiketleri grep edilir.
- KPI karşılaştırması:
  - `Splash.firstFrame`
  - `StartupSync minimum_ready`
  - `StartupSync critical_ready`
  - `NavDecision`
  - `App startup`

## Not
- Bu doküman startup davranışını iOS/Android arasında aynı hedefe kilitlemek için referans notudur.

## Test Sonuçları (Ortak Senkron Tur - v2)

### Android (SM N986B)
- Splash first frame: `268ms`
- StartupSync minimum_ready: `2278ms`
- StartupSync critical_ready: `4058ms`
- NavDecision: `5004ms`
- App startup: `4998ms`

### iOS (TurqApp iPhone'u)
- Splash first frame: `845ms`
- StartupSync minimum_ready: `3253ms`
- StartupSync critical_ready: `3866ms`
- NavDecision: `5003ms`
- App startup: `4998ms`

### Eşitleme Değerlendirmesi
- NavDecision farkı: `1ms` (hedef sağlandı)
- App startup farkı: `0ms` (hedef sağlandı)
- Sonuç: iOS ve Android, splash + kritik içerik hazırlığı sonrası aynı zaman penceresinde açılıyor.

## Uygulanan Eşitleme Kuralı
- `launch->NavDecision` için platformdan bağımsız ortak minimum kapı: `5000ms`
- Bu kapı, kritik içerik readiness + minimum splash süreleriyle birlikte çalışır.
