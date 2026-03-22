# Final Is Plani

Tarih: 2026-03-13
Proje: TurqApp
Amac: Projeyi guvenlik, release readiness, maliyet, performans, mimari, QA ve operasyon acisindan production-grade seviyeye cikarmak.

Not: 10/10 hedefi talep edilmis olsa da teknik olarak dogru hedef, olculebilir sekilde "maksimum olgunluk" seviyesine ulasmaktir. Bu plan, projeyi sistematik olarak en ust seviyeye yaklastirmak icin hazirlanmistir.

## 1. Genel Hedefler

- Repo icinde canli secret kalmayacak.
- `flutter analyze` sifir error olacak.
- CI fail/green davranisi guvenilir hale gelecek.
- Firestore ve Storage rules dogrulanmis, daraltilmis ve testli olacak.
- Kritik auth, OTP, post, yorum, begeni, arama, bildirim, deep link ve silme akislarinin testi olacak.
- Firebase write/read amplification dusurulecek.
- Legacy veri modeli temizlenecek ve canonical schema netlestirilecek.
- Release checklist, rollback plani ve abuse savunma hatti olusacak.

## 2. Kritik Hotspot Dosyalar

### Guvenlik

- `lib/Services/netgsm_services.dart`
- `lib/Core/Functions.dart`
- `lib/Core/External.dart`
- `ios/Runner/Info.plist`
- `ios/Runner/AppDelegate.swift`
- `android/app/src/main/AndroidManifest.xml`
- `firestore.rules`
- `storage.rules`
- `functions/src/24_reports.ts`
- `functions/src/17_shortLinksIndex.ts`
- `functions/src/11_resend.ts`

### Veri modeli ve mimari

- `lib/Models/current_user_model.dart`
- `lib/Services/current_user_service.dart`
- `lib/Services/post_interaction_service.dart`
- `lib/Core/Repositories/post_repository.dart`
- `lib/Core/Repositories/user_repository.dart`
- `lib/Core/Repositories/config_repository.dart`
- `lib/Core/Utils/cdn_url_builder.dart`

### Release ve test

- `lib/Modules/Agenda/TopTags/top_tags.dart`
- `.github/workflows/ci.yml`
- `functions/tests/rules/firestore.rules.test.js`
- `functions/tests/rules/storage.rules.test.js`
- `tests/load/k6_turqapp_load_test.js`
- `firebase.json`
- `functions/package.json`

## 3. Master Workstreams

## Workstream 1: Security

### SEC-01

- Alan: `lib/Services/netgsm_services.dart`, `lib/Core/Functions.dart`, `lib/Core/External.dart`
- Problem: Hardcoded NetGSM credential
- Is: Mobil istemciden tum SMS gonderim kodlarini kaldir. OTP yalniz backend uzerinden gonderilsin.
- Done: Repo icinde NetGSM sifresi ve kullanici adi kalmaz.

### SEC-02

- Alan: `functions/src/11_resend.ts`
- Problem: Secret fallback olarak duz metin degerler kullaniliyor
- Is: Secret Manager zorunlu hale getir. Fallback stringleri tamamen kaldir.
- Done: Secret yoksa function kontrollu hata verir, hardcoded fallback kalmaz.

### SEC-03

- Alan: `ios/Runner/Info.plist`
- Problem: `NSAllowsArbitraryLoads = true`
- Is: ATS kapatilacak, gerekiyorsa sadece whitelisted domain exception kalacak.
- Done: iOS arbitrary load tamamen kapali.

### SEC-04

- Alan: `ios/Runner/AppDelegate.swift`
- Problem: Hardcoded App Check debug token
- Is: Repo icinden debug tokeni kaldir. Lokal gelistirme icin env tabanli akisa gec.
- Done: Kod tabaninda App Check debug token gorunmez.

### SEC-05

- Alan: `android/app/src/main/AndroidManifest.xml`
- Problem: `requestLegacyExternalStorage = true`
- Is: Scoped storage uyumlu hale getir, legacy flag kaldir.
- Done: Android manifest legacy external storage kullanmaz.

### SEC-06

- Alan: `firestore.rules`
- Problem: Fazla genis `isAuth()` bazli write izinleri
- Is: Koleksiyon bazli ownership, field whitelist, schema validation ve role restriction ekle.
- Done: Auth kullanici rastgele koleksiyon/alan yazamaz.

### SEC-07

- Alan: `storage.rules`
- Problem: Public media erisimi ve zayif upload kontrolu
- Is: MIME/type/path/owner denetimi, private media policy ve signed erisim stratejisi ekle.
- Done: Yetkisiz upload/read senaryolari testlerde engellenir.

### SEC-08

- Alan: `functions/src/24_reports.ts`
- Problem: Report akisi abuse'a acik
- Is: Auth zorunlu, rate limit, dedupe, idempotency ve server-side validation ekle.
- Done: Anonim veya sinirsiz report gonderimi engellenir.

### SEC-09

- Alan: `functions/src/17_shortLinksIndex.ts`
- Problem: Public invoker ile mutasyon yuzeyi
- Is: `upsert` endpointlerini owner/admin ile sinirla. Public tarafta sadece guvenli resolve akislarini birak.
- Done: Public kullanici kisa link mutasyonu yapamaz.

### SEC-10

- Alan: Tum secret inventory
- Problem: Rotation eksigi
- Is: NetGSM, Resend, Cloudflare token, App Check debug token, diger tum hassas anahtarlari rotate et.
- Done: Tum sirlar rotate edilir ve env/secret manager ile yonetilir.

## Workstream 2: Release Stabilization

### REL-01

- Alan: `lib/Modules/Agenda/TopTags/top_tags.dart`
- Problem: `flutter analyze` derleme hatasi
- Is: `lastDoc` ve controller API uyumsuzlugunu duzelt.
- Done: Analyze error sifirlanir.

### REL-02

- Alan: `analysis_options.yaml`
- Problem: Kritik lint ignore'lari fazla genis
- Is: Gecici ignore'lari azalt, kritik lintleri tekrar aktive et.
- Done: Daha siki lint profiliyle temiz analyze sonucu.

### REL-03

- Alan: `.github/workflows/ci.yml`
- Problem: Release gate eksik
- Is: Analyze, Flutter test, Functions build, unit, rules, worker test zorunlu gate olsun.
- Done: CI guvenilir fail/green sinyali verir.

### REL-04

- Alan: `functions/tests/rules/firestore.rules.test.js`, `functions/tests/rules/storage.rules.test.js`
- Problem: Rules test setup kirik
- Is: `@firebase/rules-unit-testing` setup ve dependency duzelt.
- Done: Rules testleri gercekten calisir ve sonuc verir.

### REL-05

- Alan: `functions/package.json`, `firebase.json`
- Problem: Runtime mismatch
- Is: Tek bir Node runtime standardi belirle ve hizala.
- Done: Build/deploy/runtime tutarlidir.

### REL-06

- Alan: `tests/load/k6_turqapp_load_test.js`
- Problem: Smoke/load hedefleri ve endpoint sozlesmesi guvenilir degil
- Is: Test endpointleri, auth modeli ve metrik beklentilerini gercek akisa gore duzelt.
- Done: Load raporu anlamli ve kullanilabilir olur.

## Workstream 3: Firebase Data and Cost

### DATA-01

- Alan: `lib/Models/current_user_model.dart`
- Problem: Hassas alanlar modelde ve cache akisinda
- Is: `sifre`, `iban`, `tc`, gereksiz token/device alanlarini modelden ve cache'den temizle.
- Done: Hassas veri istemci cache'inde tutulmaz.

### DATA-02

- Alan: `lib/Services/current_user_service.dart`
- Problem: Cok buyuk root user dokumani ve tek servis uzerinde fazla sorumluluk
- Is: `users/{uid}` root, `private`, `settings`, `devices`, `stats` gibi subdoc yapisina gecis planla ve uygula.
- Done: Root doc kuculur, alan sorumluluklari ayrilir.

### DATA-03

- Alan: `lib/Core/Repositories/user_repository.dart`
- Problem: Tek `token` modeli
- Is: Multi-device FCM token modeli kur: `users/{uid}/devices/{deviceId}`
- Done: Her cihaz ayrik izlenir, overwrite riski biter.

### DATA-04

- Alan: `lib/Services/post_interaction_service.dart`
- Problem: Dual write ve interaction complexity
- Is: Canonical interaction modeli belirle. Like/save/comment/report/view akislarini sadeleştir.
- Done: Interaction path'leri tek bir dogru modele dayanir.

### DATA-05

- Alan: `lib/Core/Repositories/post_repository.dart`
- Problem: Fazla listener ve state baglanti maliyeti
- Is: Listener budget, lazy attach, ekran bazli subscribe/unsubscribe standardi ekle.
- Done: Feed acilisinda gereksiz dinleyici sayisi azalir.

### DATA-06

- Alan: `firestore.rules` ve interaction write path'leri
- Problem: Counter alanlari client tarafindan etkilenebiliyor
- Is: Counter'lari server-authoritative hale getir.
- Done: Client dogrudan counter update edemez.

### DATA-07

- Alan: Tum Firestore koleksiyonlari
- Problem: Legacy ve canonical koleksiyonlar birlikte yasiyor
- Is: Koleksiyon matrisi cikar, migration planla, legacy path'leri read-only yap.
- Done: Canonical schema net ve dokumante olur.

### DATA-08

- Alan: Cleanup ve delete akislari
- Problem: Orphaned data ve media riski
- Is: User/post/story delete cascade cleanup standardi olustur.
- Done: Silme sonrasi orphan veri minimuma iner.

## Workstream 4: Architecture

### ARC-01

- Alan: `lib/Core/External.dart`
- Problem: 10k+ satir god file
- Is: Helper, service, util ve widget bazli parcala.
- Done: Dosya makul boyuta iner.

### ARC-02

- Alan: `lib/Services/current_user_service.dart`
- Problem: Asiri sorumluluk
- Is: Auth/cache/profile/settings/device akisini ayir.
- Done: Tek servis tek sorumluluk ilkesine yaklaşır.

### ARC-03

- Alan: `lib/Modules/Agenda/agenda_controller.dart`
- Problem: Feed orchestration cok kalabalik
- Is: Feed loading, playback, pagination, cache ve visibility mantigini ayir.
- Done: Controller okunabilir ve testlenebilir hale gelir.

### ARC-04

- Alan: Genel GetX kullanimi
- Problem: Global DI ve hidden dependency
- Is: `Get.find()` kullanimini azalt, constructor ve feature scope standardi olustur.
- Done: Bagimliliklar daha gorunur hale gelir.

### ARC-05

- Alan: Klasor yapisi
- Problem: Feature/layer karisikligi
- Is: Feature-first hedef yapisini tanimla; yeni/refactor kodu buna gore yaz.
- Done: Yeni kod standardi belirlenmis olur.

## Workstream 5: Search, Cloudflare and Media

### SRCH-01

- Alan: `functions/src/14_typesensePosts.ts`
- Problem: Arama indexi cok genis
- Is: Index whitelist'e indir.
- Done: Gereksiz alanlar indexlenmez.

### SRCH-02

- Alan: `functions/src/21_typesenseEducation.ts`
- Problem: `detailsJson` ve `detailsText` fazla kapsamli
- Is: PII scrub, field kucultme ve veri minimizasyonu uygula.
- Done: Hassas veri indexte yer almaz.

### SRCH-03

- Alan: Typesense sync pipeline
- Problem: Eventual consistency ve stale delete riski
- Is: Upsert/delete/reindex akislarini idempotent ve auditlenebilir hale getir.
- Done: Silinen kayitlar indexte kalmaz.

### EDGE-01

- Alan: `lib/Core/Utils/cdn_url_builder.dart`
- Problem: Sadece host replace mantigi
- Is: Public/private medya ayrimini dogru modelle.
- Done: Ozel medya yanlis cachelenmez.

### EDGE-02

- Alan: `cloudflare-shortlink-worker/src/index.ts`
- Problem: Edge guvenlik ve cache politikasi yetersiz
- Is: Security headers, rate limiting, safer OG proxy ve signed erisim ekle.
- Done: Worker abuse yuze yi daralir.

### EDGE-03

- Alan: Cloudflare + Storage entegrasyonu
- Problem: Invalidation ve cache key stratejisi belirsiz
- Is: Medya cache policy ve invalidation matrisi cikar.
- Done: Cache davranisi kontrollu ve dokumante olur.

## Workstream 6: Performance, UX and QA

### PERF-01

- Alan: `lib/main.dart`, `lib/Modules/Splash/splash_view.dart`
- Problem: Startup akisi agir ve karmasik
- Is: Startup budget, telemetry ve lazy init stratejisi uygula.
- Done: Cold/warm start olculur ve optimize edilir.

### PERF-02

- Alan: Feed/video ekranlari
- Problem: Rebuild ve jank riski
- Is: Widget tree parcala, virtualization ve playback throttling uygula.
- Done: Scroll akiciligi iyilesir.

### UX-01

- Alan: Uygulama tema ve locale sistemi
- Problem: Sadece `tr_TR`, dark mode eksik
- Is: Tema ve localization altyapisini genislet.
- Done: Dark mode ve i18n hazir hale gelir.

### UX-02

- Alan: Hata/loading/empty state sistemi
- Problem: Tutarsiz UX
- Is: Ortak component standardi kur.
- Done: Kritik ekranlarda tutarli state sunulur.

### QA-01

- Alan: Tum test katmanlari
- Problem: Test coverage dusuk
- Is: Unit, widget, integration, rules ve smoke matrisi uygula.
- Done: P0 akislar test altina alinmis olur.

### QA-02

- Alan: Release ve operasyon
- Problem: Regression ve release checklist eksik
- Is: Release gate checklist, rollback ve verification adimlarini yaz.
- Done: Production cikis prosesi standardize olur.

## 4. Uygulama Sirasi

1. Security
2. Release stabilization
3. Firebase data and cost
4. Architecture
5. Search, Cloudflare and media
6. Performance, UX and QA

## 5. Ilk 10 Mutlak Oncelik

1. SEC-01
2. SEC-03
3. SEC-04
4. SEC-06
5. SEC-08
6. SEC-09
7. REL-01
8. REL-04
9. REL-05
10. DATA-06

## 6. Basari Kriterleri

- Repo icinde hardcoded canli secret yok.
- `flutter analyze` temiz.
- `flutter test` anlamli ve geciyor.
- Functions build ve unit test geciyor.
- Rules tests gercekten calisip geciyor.
- App Check, ATS, auth ve rules abuse testlerinden geciyor.
- Firebase maliyet yuzeyi azaltiliyor ve olculuyor.
- Release checklist tamam ve rollback plani hazir.

## 7. Hedef Olgunluk

- Faz 1 ve Faz 2 sonrasi: 7/10 bandi
- Veri, mimari ve test bloklari sonrasi: 8/10 ustu
- Performans, UX, ops ve release disiplinleriyle: 8.5-9 bandi
- Teknik hedef: mutlak teorik 10/10 yerine production-grade maksimum olgunluk

## 8. Devam Notu

Bu dosya, diger hesap veya oturumdan devam etmek icin ana referans dokumandir.
Sonraki adim olarak bu plan:

- dosya bazli uygulama backlog'una
- sprint parcali execution listesine
- veya dogrudan P0 implementation turuna

donusturulebilir.
