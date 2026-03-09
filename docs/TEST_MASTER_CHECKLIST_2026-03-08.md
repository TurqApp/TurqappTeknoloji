# TurqApp Master Test Checklist (2026-03-08)

Bu dokuman, `/Users/turqapp/Desktop/TurqApp` projesi icin yapilmasi gereken tum testleri tek backlog olarak listeler.

## 0) Mevcut Durum Ozeti

- [x] Temel widget smoke testi var: `test/widget_test.dart`
- [x] Yuk/perf testi var: `tests/load/k6_turqapp_load_test.js`
- [ ] Flutter unit/widget kapsamli test paketi yok
- [ ] `integration_test/` klasoru yok
- [ ] `functions/` icin test runner yok
- [ ] `cloudflare-shortlink-worker/` icin test runner yok
- [ ] Firestore/Storage emulator rules test paketi yok

## 1) CI Quality Gate (P0)

- [ ] `flutter analyze` zorunlu gate
- [ ] `flutter test --coverage` zorunlu gate
- [ ] Functions test komutu (`npm test`) zorunlu gate
- [ ] Worker test komutu (`npm test`) zorunlu gate
- [ ] Firestore rules emulator test komutu zorunlu gate
- [ ] Storage rules emulator test komutu zorunlu gate
- [ ] k6 smoke profili (`tests/load/k6_turqapp_load_test.js`) nightly gate

## 2) Flutter Unit Testleri

## 2.1 Auth / SignIn (`lib/Modules/SignIn`)

- [ ] Form validasyonlari: ad/soyad/telefon formati
- [ ] OTP sure sayaci dogru azalir/sifirlanir
- [ ] OTP yanlis/dogru giris akisi
- [ ] Kayit sonrasi user dokumani dogru schema ile olusur
- [ ] Tekrar giriste `pending_deletion` hesabin restore edilmesi
- [ ] Zorunlu takip (`mandatory follow`) tetikleme davranisi
- [ ] Session degisiminde cache temizligi
- [ ] Coklu tiklama durumunda duplicate signup/login engelleme

## 2.2 Feed / Agenda (`lib/Modules/Agenda`)

- [ ] Render edilemeyen video postlarinin filtrelenmesi
- [ ] Gizli hesap + takip iliskisi gorunurluk kurali
- [ ] Scroll ile centered index hesaplama dogrulugu
- [ ] `centeredIndex` degisince tek video oynatma (digerlerini durdurma)
- [ ] Feed prefetch kuyrugu olusturma kurallari
- [ ] Cache warmup tetikleme (`ensureFeedCacheWarm`)
- [ ] Pull-to-refresh ve pagination akisi
- [ ] Feed listesinde duplicate post dedupe
- [ ] Hidden/deleted postlarin listeden dislanmasi

## 2.3 Chat (`lib/Modules/Chat`)

- [ ] Mesaj model parse/serialize
- [ ] Typing heartbeat yazma/sifirlama (`typing.{uid}`)
- [ ] Offline modda lokal pencere yukleme
- [ ] Server senkron araligi (wifi/mobile/offline) kurali
- [ ] Yukleme yuzde/ilerleme state gecisleri
- [ ] Medya turlerine gore gonderim akisi (image/video/audio/location)
- [ ] NSFW red/allow sonuclarina gore davranis
- [ ] `loadOlderMessages` cursor dogrulugu
- [ ] Realtime stream + polling cakisinca duplicate mesaj engelleme
- [ ] Sohbet acildiginda unread sifirlama
- [ ] Sohbet kapanisinda son acilis zamaninin yazilmasi
- [ ] Reply/edit/selection mode durum gecisleri

## 2.4 Story (`lib/Modules/Story`)

- [ ] Story row listeleme + cache-first davranis
- [ ] Story viewer ilerleme timer akisi
- [ ] Story seen/like/comment yazma
- [ ] 24 saat gecmis storylerin gorunurluk kurali
- [ ] Story highlight secme/olusturma akisi
- [ ] Story maker text/sticker/drawing state dogrulugu
- [ ] Story video/image upload state gecisleri

## 2.5 Short / Video (`lib/Modules/Short`, `lib/hls_player`)

- [ ] Dynamic short route parse (docId ile acilis)
- [ ] HLS ready olmayan icerigin fallback davranisi
- [ ] HLS controller lifecycle (init/dispose)
- [ ] Segment cache hit/miss/eviction
- [ ] Arka plana geciste player pause
- [ ] Taba donuste hedef videonun resume edilmesi

## 2.6 Post Creator / Social Interaction

- [ ] Caption hashtag/mention parse
- [ ] Media validation (boyut/tur/sure)
- [ ] Upload queue enqueue/dequeue/retry
- [ ] Like/save/comment/share optimistic update + rollback
- [ ] Reshare dedupe kurali
- [ ] Report post akisi
- [ ] Post delete soft-delete alanlarinin dogru set edilmesi

## 2.7 Profile / Settings

- [ ] Profil duzenleme alan validasyonlari
- [ ] Follow/unfollow sayaç senkronu
- [ ] Block/unblock davranisi
- [ ] Ayarlar toggles kaliciligi
- [ ] Versiyon kontrolu (`checkAppVersion`) fail-open davranisi

## 2.8 Education (`lib/Modules/Education`)

- [ ] Sinav/kitapcik liste query filtreleri
- [ ] Sonuc hesaplama (dogru/yanlis/net)
- [ ] Cikmis sorular filtre adimlari
- [ ] Ozel ders basvuru olusturma
- [ ] Burs basvuru create/update durumlari
- [ ] Buyuk liste ekranlarinda pagination ve duplicate engelleme

## 2.9 JobFinder (`lib/Modules/JobFinder`)

- [ ] Is ilani listeleme filtre/siralama
- [ ] Basvuru olusturma (tekil basvuru kurali)
- [ ] Kaydedilen ilan ekle/cikar
- [ ] Ilan detaydan geri donus state koruma

## 2.10 Core Servisleri

- [ ] `lib/Core/Services/lru_cache.dart` evict/removeWhere
- [ ] `upload_queue_service.dart` retry/backoff ve kalicilik
- [ ] `media_compression_service.dart` basari/hata fallback
- [ ] `video_compression_service.dart` timeout/failure
- [ ] `mandatory_follow_service.dart` idempotency
- [ ] `error_handling_service.dart` hata siniflandirma
- [ ] `notification_services.dart` token yoksa fail-safe
- [ ] `offline_mode_service.dart` queue replay
- [ ] `current_user_service.dart` cache TTL + stream senkronu

## 2.11 Model / Serialization

- [ ] Tum kritik modellerde `fromJson/toJson` roundtrip
- [ ] Null/missing field fallback degerleri
- [ ] Legacy field adlariyla geriye donuk uyumluluk

## 3) Flutter Widget Testleri

- [ ] NavBar sekmeleri (Agenda/Explore/Short/Education/Profile)
- [ ] Back navigation kurallari (`NavBarView._handleBackNavigation`)
- [ ] Agenda post karti render varyantlari (text/image/video)
- [ ] Chat mesaj balonlari (gonderen/alici, reply, secili)
- [ ] Story viewer UI states (loading/empty/error)
- [ ] SignIn ekranlari (login/register/reset) form hata metinleri
- [ ] Profile ekrani ve follow buton durumlari
- [ ] Education liste/grid ekranlari (bos/icerik/yukleniyor)
- [ ] JobFinder kart/list widgetlari
- [ ] Offline indicator gorunurlugu

## 4) Flutter Integration / E2E Testleri

- [ ] Yeni kullanici kayit -> onboarding -> ana ekran
- [ ] Login -> feed acilis -> scroll -> video autoplay
- [ ] Post olustur (image/video) -> feedde gor -> sil
- [ ] Like/comment/share/reshare tam akisi
- [ ] Follow/unfollow -> sayac senkronu
- [ ] DM ac -> mesaj at -> medya gonder -> typing goster
- [ ] Story olustur -> goruntule -> seen/like/comment
- [ ] Search user/tag -> profile ac -> geri don
- [ ] Education: sinav coz -> sonuc kaydet
- [ ] JobFinder: ilan incele -> basvur -> basvuru listesinde gor
- [ ] Offline -> aksiyon biriktir -> online -> replay
- [ ] Multi-device race: ayni posta ayni anda etkileisim

## 5) Cloud Functions Testleri (`functions/src`)

## 5.1 Rules/Guard ve Yardimci Fonksiyon Unit Testleri

- [ ] `rateLimiter.ts` limit asimi/normal gecis
- [ ] Env yok/hatali env durumlarinda hata kodu dogrulugu
- [ ] Auth zorunlulugu olan callable fonksiyonlarda `unauthenticated`
- [ ] Admin zorunlulugu olanlarda `permission-denied`

## 5.2 Tag/Typesense

- [ ] `04_tagSettings.ts` hashtag/caption tag extraction
- [ ] stopword/bannedword filtreleri
- [ ] `14_typesensePosts.ts` index upsert/delete senaryolari
- [ ] `15_typesenseUsersTags.ts` user/tag search callable
- [ ] limit/cursor parametre validasyonu
- [ ] Typesense timeout/retry/fallback
- [ ] `16_tagMaintenance.ts` reconcile/prune dry-run ve gerçek calisma

## 5.3 User/Profile/Email

- [ ] `09_userProfile.ts` profile degisince post author alanlari sync
- [ ] `11_resend.ts` code olusturma/dogrulama/sure asimi
- [ ] Email degisimi + phone update kombinasyon akisi

## 5.4 Short Link

- [ ] `17_shortLinksIndex.ts` upsert (post/story/user/edu/job) tipleri
- [ ] shortId/slug validasyonlari
- [ ] Cloudflare KV sync cagrisinin basari/hata senaryolari
- [ ] `resolveShortLink` aktif/pasif/suresi dolmus link

## 5.5 Media Pipelines

- [ ] `thumbnails.ts` image thumbnail olusumu
- [ ] `hlsTranscode.ts` video yukle -> hls output -> metadata patch
- [ ] hata durumunda status alanlarinin dogru set edilmesi

## 5.6 Feed ve Counter

- [ ] `counterShards.ts` `recordViewBatch` shard dagitimi
- [ ] scheduled aggregation sonucunun ana dokumana yazilmasi
- [ ] `hybridFeed.ts` post create/delete follower fanout
- [ ] follower eklendiginde gecmis post backfill davranisi

## 5.7 Index Triggers (`functions/src/index.ts`)

- [ ] `syncUserSchemaAndFlags` canonical patch dogrulugu
- [ ] `enforceMandatoryFollowOnUserCreate` idempotent edge yazimi
- [ ] `onUserDocDelete` ve `onUserDocUpdate` phoneAccounts senkronu
- [ ] `onUserNotificationCreate` push acik/kapali tip kontrolu
- [ ] `processScheduledAccountDeletions` pending->completed akisi
- [ ] `resetMonthlyAntPoint` tum sayfalarda batch reset
- [ ] Admin utility callables (backfill/purge/migrate) path validasyonlari

## 6) Cloudflare Worker Testleri (`cloudflare-shortlink-worker/src/index.ts`)

- [ ] Route parse (`/p|s|u|e|i/:id`) gecerli/gecersiz
- [ ] KV hit/miss + resolve fallback
- [ ] `/.well-known/*` endpointleri
- [ ] Bot UA icin OG HTML donusu
- [ ] Normal UA icin deep link fallback HTML
- [ ] Story expiry (`expiresAt`) davranisi
- [ ] Email action token akisi (`e/*` tokenli)
- [ ] `og-image` proxy basari, upstream fail, fallback redirect
- [ ] XSS-safe text/url escaping (`safeText`, `safeUrl`)

## 7) Firestore Rules Emulator Testleri (`firestore.rules`)

- [ ] `users/{uid}` read/write owner disi engeli
- [ ] Moderasyon alanlarini client update edememe
- [ ] followers/followings edge write kurali
- [ ] notifications payload schema + type whitelist
- [ ] users_usernames rezervasyon kurali
- [ ] posts create/update/delete yetkileri
- [ ] post subcollections (likes/comments/views/reports) yetkileri
- [ ] conversations/messages read-write participant kurali
- [ ] adminConfig dokumanlarinda admin-only yazma
- [ ] default deny kurali (bilinmeyen pathlerde)

## 8) Storage Rules Emulator Testleri (`storage.rules`)

- [ ] `users/{uid}/**` sadece owner write (boyut limiti dahil)
- [ ] `Posts/{postId}/**` owner veya bypass write
- [ ] HLS/thumbnail pathlerinde public read + write deny
- [ ] `stories/{uid}/**` owner write + limit
- [ ] `Chat|Mesajlar|ChatAssets/{chatId}/**` participant kurali
- [ ] `public/**` read everyone, write denied
- [ ] root-level file read auth zorunlulugu
- [ ] default write deny

## 9) Performans / Yuk / Dayaniklilik Testleri

- [ ] k6 smoke profilinde threshold tutarliligi
- [ ] feed-only, network, social-interaction profilleri tekrar kosum
- [ ] Cold vs warm feed p95 dogrulugu
- [ ] CF callable p99 gecikme olcumu
- [ ] Error rate < %0.5 dogrulugu
- [ ] Uzun sureli soak test (en az 1 saat)
- [ ] Chat flood/rate-limit davranisi
- [ ] Story ve video yukleme throughput testi

## 10) Mobil Stabilite ve Release Smoke (Manuel)

- [ ] Android low-end cihaz: scroll jank / memory
- [ ] iOS release build: startup, push, deep-link
- [ ] Uygulama arkaplan/onkplan gecislerinde medya pause/resume
- [ ] Bildirimden uygulama acilis senaryolari
- [ ] Kamera/mikrofon/galeri izin reddi akislari
- [ ] Ucak modu gecisinde kritik akislarda crash olmamasi
- [ ] App update zorlamasi (`checkAppVersion`) dogru calisma

## 11) Exit Kriterleri

- [ ] P0 maddeleri %100 tamam
- [ ] Flutter unit+widget coverage >= %60 (ilk hedef)
- [ ] Functions + rules testleri kritik fonksiyonlar icin >= %80
- [ ] E2E kritik yolculuklarin tamami pass
- [ ] Son k6 raporunda tum zorunlu thresholdlar PASS

## 12) Calistirma Komut Onerileri

```bash
# Flutter
flutter analyze
flutter test --coverage

# Cloud Functions (test runner eklendikten sonra)
cd functions
npm test

# Cloudflare Worker (test runner eklendikten sonra)
cd cloudflare-shortlink-worker
npm test

# k6
k6 run tests/load/k6_turqapp_load_test.js
```

