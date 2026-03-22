# TurqApp Test System

Tarih: 2026-03-22

Bu dosya TurqApp mobil kalite sisteminin kanonik test dokumanidir.
Amac:

- resmi release-gate test setini sabitlemek
- mevcut coverage durumunu netlestirmek
- Android gercek cihaz E2E hattini tek yerde tarif etmek
- Phase 3 derin fonksiyonel bosluklarini test seviyesiyle tanimlamak
- yeni testler master sete alinmadan once hangi kosullari saglamasi gerektigini yazmak

## Temel Kalite Hedefleri

- kritik kullanici yolculuklarinda crash, blank screen veya route-stuck olmamasi
- feed, short ve fullscreen arasinda playback ownership bozulmamasi
- kullanicinin gercek girdigi akislarda sessiz veri kaybi veya sahte yesil test olmamasi
- notification, comment, story, chat ve pasaj akislarinda hedef ekranin dogru acilmasi
- uzun oturumlarda memory trendinin kontrolsuz buyumemesi
- testlerin gercek backend ile kosarken kontrollu ve non-destructive olmasi

## Kanonik Test Envanteri

### 1. Resmi release-gate master set

Bu set bugun tek komutta kosulan resmi E2E zinciridir.
Script:

- `scripts/run_turqapp_master_e2e.sh`

Test entrypointleri:

1. `integration_test/turqapp_complete_e2e_test.dart`
2. `integration_test/feed/feed_black_flash_smoke_test.dart`
3. `integration_test/feed/feed_fullscreen_audio_smoke_test.dart`
4. `integration_test/feed/feed_network_resilience_smoke_test.dart`
5. `integration_test/feed/feed_normal_scroll_playback_smoke_test.dart`
6. `integration_test/shorts/short_first_two_playback_test.dart`
7. `integration_test/feed/turqapp_audio_ownership_e2e_test.dart`
8. `integration_test/feed/hls_data_usage_suite_test.dart`

Bu 8 test bugun resmi kalite kapisidir.

### 2. Genisletilmis uzman smoke havuzu

Repoda master sete henuz alinmamis ama teknik degeri yuksek ek testler de vardir.
Bunlar bugun uzman sweep, regresyon avciligi veya sertlestirme havuzu olarak degerlendirilmelidir.

Feed ve playback odakli:

- `integration_test/feed/feed_production_smoke_suite_test.dart`
- `integration_test/feed/feed_native_exoplayer_truth_smoke_test.dart`
- `integration_test/feed/feed_first_video_autoplay_test.dart`
- `integration_test/feed/feed_first_video_playback_test.dart`
- `integration_test/feed/feed_five_post_scroll_and_return_test.dart`
- `integration_test/feed/feed_ten_video_smoke_test.dart`
- `integration_test/feed/feed_resume_test.dart`

Short odakli:

- `integration_test/shorts/short_ten_video_smoke_test.dart`
- `integration_test/shorts/short_five_item_playback_stress_test.dart`
- `integration_test/shorts/short_refresh_preserve_test.dart`
- `integration_test/shorts/short_landscape_filter_smoke_test.dart`

Route replay ve yuzey acilisi:

- `integration_test/explore/explore_preview_gate_test.dart`
- `integration_test/profile/profile_resume_test.dart`
- `integration_test/notifications/notifications_snapshot_mutation_test.dart`
- `integration_test/chat/chat_listing_smoke_test.dart`
- `integration_test/profile/profile_feed_video_smoke_test.dart`

### 3. Ortak test altyapisi

Flutter helper katmani:

- `integration_test/core/bootstrap/test_app_bootstrap.dart`
- `integration_test/core/helpers/turqapp_complete_e2e_flow.dart`
- `integration_test/core/helpers/route_replay.dart`
- `integration_test/core/helpers/smoke_artifact_collector.dart`
- `integration_test/core/helpers/e2e_progress_tracker.dart`
- `integration_test/core/helpers/e2e_matrix_logger.dart`
- `integration_test/core/helpers/test_state_probe.dart`
- `integration_test/core/helpers/native_exoplayer_probe.dart`
- `integration_test/core/helpers/perf_monitor.dart`

Script katmani:

- `scripts/run_turqapp_master_e2e.sh`
- `scripts/run_turqapp_test_smoke.sh`
- `scripts/run_integration_smoke.sh`

Native truth katmani:

- Android:
  - `android/app/src/main/kotlin/com/turqapp/app/ExoPlayerView.kt`
  - `android/app/src/main/kotlin/com/turqapp/app/qa/ExoPlayerSmokeRegistry.kt`
  - `android/app/src/main/kotlin/com/turqapp/app/qa/ExoPlayerPlaybackProbe.kt`
  - `android/app/src/main/kotlin/com/turqapp/app/qa/PlaybackWatchdog.kt`
- iOS:
  - `ios/Runner/HLSPlayerView.swift`
  - `ios/Runner/AVPlayerPlaybackProbe.swift`
  - `ios/Runner/PlaybackWatchdog.swift`

## Katmanli Test Stratejisi

1. Unit ve service dogrulamasi
- parser, budget, threshold, telemetry ve invariant mantigi

2. Replay smoke
- route replay
- state probe
- count-zero-drop gibi continuity assertionlari

3. Domain specialist smoke
- feed playback
- short playback
- audio ownership
- black flash
- HLS data budget

4. Complete journey E2E
- launch
- auth
- tab traversal
- profile
- composer draft
- comments
- notifications
- short
- story viewer

5. Deep functional E2E
- gercek reply send
- gercek chat send
- deep-link target route
- story reply/reaction
- pasaj detail

6. Long session ve trend testleri
- 10-15 dakikalik route churn
- memory trend
- jank trend
- ownership leak
- resume restore

## Mevcut Coverage Durumu

| Alan | Durum | Not |
| --- | --- | --- |
| launch + auth bootstrap | TAM | master E2E ve smoke bootstrap guclu |
| auth/session lifecycle | KISMI | login bootstrap var; logout, stored-session reauth, account-switch churn yok |
| feed playback ve ownership | TAM | master + uzman smoke havuzu guclu |
| profile temel akislar | TAM | edit, settings, QR, profile-chat entry var |
| explore temel akislar | KISMI | tab traversal var, search mode derin degil |
| comments | KISMI | comment send var, gercek reply send ve delete yok |
| chat | KISMI | listing, tabs, search, create yuzeyi var; gercek conversation send yok |
| social graph ve safety | KISMI | profile acilisi var; follow/unfollow, report/block otomatik degil |
| notifications | KISMI | more menu ve replay var; item deep-link target assertion yok |
| short | KISMI | playback guclu; gercek source-entry single short akisi yok |
| story | KISMI | story viewer entry var; reply/reaction yok |
| story management | YOK | story maker, highlights, deleted stories, music akislarinin E2E kapsami yok |
| market | KISMI | tab seviyesi var; detail deep flow yok |
| education detaylari | KISMI | tab seviyesi var; burs/job/test solve derinligi yok |
| passage owner/applicant akislar | YOK | apply, save, create, review, owner menu mutasyonlari otomatik degil |
| post creation publish | KISMI | draft girisi var; publish, upload, local insert, refresh persistence yok |
| permission-gated akislar | YOK | kamera, galeri, mikrofon, konum prompt ve deny/allow matrixi yok |
| settings/raw-form round-trip | KISMI | profile edit var; alt formlarda save sonrasi yansima ve persistence otomatik degil |
| offline/resume | KISMI | feed/short odakli iyi; tam uygulama state restore derin degil |
| long session + memory trend | KISMI | 2-3 dakikalik stress var; 10-15 dakika lane yok |
| iOS eslenik E2E lane | YOK | native tanilama var, kanonik iOS E2E lane yok |

## Bugunku Release Gate Kurali

Hard gate:

- resmi 8 master test yesil olacak
- test sonunda fatal Flutter exception kalmayacak
- blocking smoke artifact cikarsa release gate dusurulecek
- HLS ve playback kritik thresholdlari bloklayici kalacak

Soft gate:

- genisletilmis uzman smoke havuzu bugun zorunlu degil
- ama yeni playback, route veya ownership regressionsa ilk bakilacak yer bu havuzdur

Promosyon kurali:

Bir test Phase 3'ten resmi master sete ancak su kosullarla alinabilir:

1. gercek cihazda en az 3 ard arda yesil kosu
2. en az 10 kosuda flake orani %5 altinda
3. destructive olmayan veri kontrati netlesmis
4. artifact ve fail anlasilirligi yeterli
5. runtime maliyeti release gate'i pratik olmayan noktaya tasimiyor

## Phase 3 Derin Fonksiyonel Hedefler

Bu alanlar bugun kismi veya yok durumundadir.
Asagidaki testler eklendiginde sistem "uygulamanin tum islevsel derinligi" tarafina anlamli sekilde yaklasmis olacaktir.

### Phase 3 ozet matrisi

| Oncelik | Alan | Onerilen entrypoint | Bugunku durum | Gate hedefi |
| --- | --- | --- | --- | --- |
| P0 | comment reply send | `integration_test/comment_reply_send_e2e_test.dart` | YOK | master adayi |
| P0 | comment delete | `integration_test/comment_delete_e2e_test.dart` | YOK | master adayi |
| P0 | chat conversation send | `integration_test/chat_conversation_send_e2e_test.dart` | YOK | master adayi |
| P0 | notifications deep-link route | `integration_test/notifications_deeplink_route_e2e_test.dart` | YOK | master adayi |
| P1 | single short real entry | `integration_test/short_real_entry_e2e_test.dart` | YOK | uzman smoke -> master |
| P1 | story reply + reaction | `integration_test/story_reply_reaction_e2e_test.dart` | YOK | uzman smoke |
| P1 | market detail deep flow | `integration_test/market_detail_deep_e2e_test.dart` | YOK | uzman smoke |
| P1 | scholarship/job/test solve deep flows | `integration_test/education_detail_deep_e2e_test.dart` | YOK | uzman smoke |
| P0 | long session stress + memory | `integration_test/long_session_stress_memory_e2e_test.dart` | YOK | ayrica nightly lane |

## Phase 3 Ayrintili Test Tasarimi

### 1. Comment Reply Send E2E

Amac:

- kullanicinin yorum ekraninda gercek bir yoruma reply yazip gonderebildigini dogrulamak

Risk:

- reply target baglanmiyor
- text localde gorunup backend'e dusmuyor
- reply parent-child iliskisi kopuk kalıyor
- clear reply ve refresh sonrasi reply kayboluyor

Onerilen akis:

1. feed ac
2. deterministic ilk postu bul
3. comments ekranina gir
4. reply alinabilir bir yorumu sec
5. reply moduna gir
6. unique `e2e-reply-<timestamp>` metni gir
7. send yap
8. local listede reply'yi ve parent bagini dogrula
9. refresh veya route return sonrasi reply'nin hala okunabildigini dogrula

Minimum assertion:

- reply mode aktif oldu
- parent yorum anahtari secildi
- send sonrasi loading sonsuza kalmadi
- reply metni listede gorundu
- reply parent veya thread iliskisi korunuyor
- test sonunda fatal exception yok

Non-destructive kontrat:

- sadece test kullanicisinin sahip oldugu fixture post ve fixture comment uzerinde kos
- reply metni `E2E_REPLY:` prefix'i tasiyacak
- gerekirse TTL veya cleanup mekanizmasi ile temizlenebilir olacak

Artifact:

- sent reply id
- parent comment id
- route dump
- comments surface probe

### 2. Comment Delete E2E

Amac:

- test kullanicisinin kendi olusturdugu yorum veya reply'yi silebildigini dogrulamak

Risk:

- delete action gorunup backend'e islenmiyor
- optimistic remove sonrasi ghost item geri geliyor
- counter veya thread yapisi bozuluyor

Onerilen akis:

1. deterministic post comments ekranina gir
2. teste ait unique yorum olustur
3. yorumun ekranda gorundugunu dogrula
4. delete aksiyonunu tetikle
5. confirm varsa onayla
6. itemin listeden kalktigini dogrula
7. refresh sonrasi geri gelmedigini dogrula

Minimum assertion:

- silme aksiyonu sadece own-comment uzerinde gorunuyor
- delete sonrasi item yok oluyor veya tombstone bekleniyorsa beklenen state'e geciyor
- comment count negatif veya tutarsiz olmuyor
- route return sonrasi ghost item geri donmuyor

Non-destructive kontrat:

- sadece testin ayni kosuda olusturdugu yorumu sil
- fixture disi organik kullanici yorumuna dokunma

Artifact:

- created comment id
- deleted comment id
- before/after comment count

### 3. Chat Conversation Send E2E

Amac:

- kullanicinin gercek bir conversation acip mesaji gonderebildigini ve ack aldigini dogrulamak

Risk:

- conversation aciliyor ama message persist olmuyor
- local optimistic state var ama remote ack yok
- last message ve unread state tutarsiz kaliyor

Onerilen akis:

1. chat sekmesine git
2. fixture peer kullanicisi ile deterministic conversation ac
3. conversation ekraninin acildigini dogrula
4. unique `E2E_CHAT:<timestamp>` mesaji gonder
5. local bubble, status ve timestamp gorunumunu dogrula
6. gerekirse route geri donup listingte son mesaji dogrula
7. tekrar conversation'a girip mesajin kalici oldugunu dogrula

Minimum assertion:

- screen chat listing degil, gercek message content ekranina gecti
- send action disable-lock'a takilmadi
- gonderilen metin local listede gorundu
- backend ack veya persisted state goruldu
- chat listing son mesaj preview guncellendi

Non-destructive kontrat:

- sadece E2E peer hesabiyla kos
- test metinleri belirgin prefix tasiyacak
- mumkunse cleanup unsend veya test thread kullan

Artifact:

- peer uid
- thread id
- sent message id
- listing snapshot once/sonra

### 4. Notifications Deep-Link Route E2E

Amac:

- notification item'e basildiginda hedef route ve hedef modelin dogru acildigini dogrulamak

Risk:

- item tap sadece notifications ekranini kapatiyor
- yanlis route aciliyor
- route aciliyor ama yanlis doc/model yukleniyor
- empty fallback sessizce geciyor

Onerilen fixture:

- en az bir routeable notification:
  - comment/post target
  - chat target
  - market veya education target

Onerilen akis:

1. notifications ekranina gir
2. routeable item'i sec
3. item metadata veya fixture beklenen hedefi belirle
4. item'e tap yap
5. route adini, screen key'i ve hedef doc id'yi dogrula
6. back ile notifications veya navbar akisinin bozulmadigini dogrula

Minimum assertion:

- tap sonrasi route degisti
- beklenen ekran key'i gorundu
- beklenen hedef doc id veya target id probe'da mevcut
- unread/update state tutarsizligi yok

Non-destructive kontrat:

- test fixture notification veri seti kullan
- prod dogal bildirimlerin tip/icerik belirsizligine baglanma

Artifact:

- tapped notification id
- expected route
- actual route
- expected target id
- actual target id

### 5. Single Short Real Entry E2E

Amac:

- `SingleShortView`e dogrudan test icinden `Get.to()` ile degil, uygulamanin gercek giris noktasindan gidildigini dogrulamak

Risk:

- entry handoff ile programatik handoff farkli davranıyor
- source route state'i bozuluyor
- geri donuste scroll veya playback sahipligi kayboluyor

Onerilen akis:

1. short'a feed, profile veya explore gibi gercek bir kaynaktan gir
2. bir short tile veya short kartina kullanici gibi tap yap
3. single short detay ekraninin acildigini dogrula
4. beklenen doc id'nin acilan detaya tasindigini dogrula
5. playback continuity ve audio ownership'i dogrula
6. back ile kaynak route'a dogru don
7. kaynak route state'inin korundugunu dogrula

Minimum assertion:

- giris kullanici aksiyonu ile oldu
- expected source route kaydedildi
- acilan short dogru doc id'ye ait
- geri donuste kaynak ekran kaybolmadi

Artifact:

- source route
- source short doc id
- opened short doc id
- return route

### 6. Story Reply and Reaction E2E

Amac:

- story row -> story viewer -> reply/reaction zincirini gercek kullanici aksiyonuyla dogrulamak

Risk:

- story viewer aciliyor ama interaksiyon kanallari kirik
- reaction localde gorunup backend'e gitmiyor
- reply input focus/send zinciri kirik

Onerilen akis:

1. feed story row'u bul
2. story viewer'a gir
3. reaction gonder
4. reply input varsa unique reply gonder
5. local success sinyalini dogrula
6. viewer kapanip feed'e donus veya next story akisinin kirilmadigini dogrula

Minimum assertion:

- story viewer acildi
- reaction action gercekten tetiklendi
- reply input acilabildi
- send sonrasi error snackbar gelmedi
- route veya playback yan etkisi olusmadi

Non-destructive kontrat:

- test story fixture kullan
- reply metni `E2E_STORY_REPLY:` prefix'i tasisin

Artifact:

- story owner id
- story id
- reaction type
- reply text hash

### 7. Market Detail Deep E2E

Amac:

- market sekmesinden detail ekranina inis ve detail iceriginin gercek veriyle dogrulanmasi

Risk:

- listeden detail route bozuk
- detail controller yanlis item yukluyor
- image, title, owner veya CTA bloklari eksik geliyor

Onerilen akis:

1. education/pasaj gir
2. market tabina gec
3. deterministic ilk test ilani ac
4. detail ekraninda title, fiyat, durum, owner veya ana CTA bloklarini dogrula
5. geri donuste liste state'inin korundugunu dogrula

Minimum assertion:

- listeden detail route'a gercek tap ile gidildi
- expected detail screen key'i veya route goruldu
- acilan item doc id beklenen listing ile eslesti
- temel detail alanlari bos degil

Artifact:

- source listing id
- detail listing id
- route name

### 8. Education Detail Deep E2E

Amac:

- scholarships, job finder ve test solve akislarinin tab seviyesinden detail/islem seviyesine inmesini dogrulamak

Bu alan tek dev test yerine alt parcali ama ayni dosyada veya ayni ailede tutulmalidir:

- burs detay
- job finder detay
- practice exam veya test solve

Onerilen akislar:

Scholarship:

1. scholarships tabina gir
2. deterministic item ac
3. burs detay ekranini dogrula
4. title, kurum, basvuru veya tarih bloklarini dogrula

Job finder:

1. job finder tabina gir
2. deterministic job ac
3. job details ekranini dogrula
4. title, sirket veya basvuru CTA'sini dogrula

Test solve:

1. question bank, practice exams veya online exam icinden uygun deterministic teste gir
2. en az bir soru veya preview/solve state'ini gor
3. answer/select/next gibi temel aksiyonun kirik olmadigini dogrula

Minimum assertion:

- her alt akis gercek route ile detail/solve ekranina iner
- dogru model/doc id tasinir
- ekran placeholder/empty state'te kalmaz
- back navigation stabil kalir

Artifact:

- tab id
- selected item id
- opened detail route
- solve phase marker

### 9. Long Session Stress and Memory E2E

Amac:

- 10-15 dakikalik gercek cihaz turunda route churn, resume, ownership ve memory trendini birlikte dogrulamak

Risk:

- kisa testlerde cikmayan leak'ler
- route gecislerinde biriken player/controller state'i
- uzun sure sonra gelen off-screen audio
- resume sonrasi stale state veya kilitlenme

Onerilen lane:

- nightly veya release-candidate lane
- master gate'ten ayri kosmali
- gercek cihaz tercih edilmeli

Onerilen akis:

1. launch + auth
2. feed 3-5 dk normal/aggressive scroll
3. short 2-3 dk swipe ve bekleme
4. explore/profile/chat/notifications/education rotation
5. en az 3 kez background/foreground
6. finalde tekrar feed ve short ownership dogrulamasi

Minimum telemetry:

- baseline memory
- her 30 saniyede process memory snapshot
- severe jank ratio
- route history
- active player snapshot
- off-screen audio assertion sonucu

Ilk onerilen bloklayici thresholdlar:

- test boyunca fatal exception yok
- uygulama route-stuck durumuna girmiyor
- off-screen audible playback yok
- final memory - baseline memory < 350 MB
- herhangi bir 2 dakikalik pencerede kontrolsuz surekli yukselis varsa alarm
- son 2 dakikada recovery belirtisi yoksa fail

Not:

- Bu thresholdlar ilk sert oneridir.
- Gercek cihaz trendleri toplandikca revize edilebilir.

Artifact:

- zaman serili memory snapshotlari
- route history JSONL
- final perf raporu
- native player diagnostic dump

## Phase 3.5 Ikinci Halka Bosluklar

Bu grup "cekirdek Phase 3" kadar dogrudan release gate adayi olmayabilir, ama bunlar eklenmeden test sistemi operasyonel olarak tam sayilmaz.
Ozellikle regression geldikten sonra gec fark edilen alanlar genelde buradan cikar.

### Phase 3.5 ozet matrisi

| Oncelik | Alan | Onerilen entrypoint | Bugunku durum | Not |
| --- | --- | --- | --- | --- |
| P1 | auth/session churn | `integration_test/auth_session_churn_e2e_test.dart` | YOK | logout, stored session, account switch, reauth |
| P1 | explore real search + recent search | `integration_test/explore_search_mode_e2e_test.dart` | YOK | query, result, recent search restore |
| P1 | social graph + safety | `integration_test/social_graph_safety_e2e_test.dart` | YOK | follow/unfollow, report, block |
| P1 | post publish + media persistence | `integration_test/post_publish_persistence_e2e_test.dart` | YOK | non-destructive publish varyanti, refresh persistence |
| P1 | permission matrix | `integration_test/permission_matrix_e2e_test.dart` | YOK | camera, gallery, microphone, location |
| P1 | passage applicant + owner mutasyonlari | `integration_test/passage_actions_e2e_test.dart` | YOK | apply, save, create, owner review/action |
| P2 | story management | `integration_test/story_management_e2e_test.dart` | YOK | maker, highlights, deleted stories, music |
| P1 | settings raw-form round-trip | `integration_test/settings_roundtrip_e2e_test.dart` | YOK | save sonrasi UI yansimasi ve persistence |

### 1. Auth Session Churn E2E

Amac:

- login bootstrap'in otesine gecip logout, stored account, account switch ve reauth path'lerinin kirik olmadigini gostermek

Kritik assertion:

- logout sonrasi route sign-in/splash hattina temiz doner
- stored account ile geri giris mumkunse saglikli tamamlanir
- `requiresReauth` durumunda sessiz sahte oturum kalmaz
- account switch sonrasi eski kullanici state'i sızmaz

### 2. Explore Search Mode E2E

Amac:

- explore icinde gercek arama sorgusu, sonuc acilisi, geri donus ve recent search persistence'ini dogrulamak

Kritik assertion:

- sorgu input'a girer
- sonuc listesi bos-state'e yanlis dusmez
- sonuc item'den profile veya hedef ekran acilir
- geri donuste recent search beklenen sekilde gorunur

### 3. Social Graph and Safety E2E

Amac:

- sosyal baglanti ve guvenlik akislarinin sadece ekran acilisi degil, gercek mutasyon bazinda calistigini gostermek

Kritik assertion:

- follow/unfollow counter state'i degisir
- blocked user listesi ve report akisi beklenen state'e gecer
- geri donuste counter veya CTA ghost-state'te kalmaz

### 4. Post Publish and Persistence E2E

Amac:

- composer draft acilisinin otesine gecip guvenli bir publish varyantini ve sonrasindaki persistence'i dogrulamak

Kritik assertion:

- metin veya kontrollu media ile post olusturulur
- local insert beklenen yerde gorunur
- refresh veya route return sonrasi post kaybolmaz
- test verisi non-destructive prefix ve cleanup stratejisi tasir

### 5. Permission Matrix E2E

Amac:

- kamera, galeri, mikrofon ve konum gibi izinli akislarin deny/allow davranisini otomatik izlemek

Kritik assertion:

- deny halinde ekran kilitlenmez
- allow halinde akis devam eder
- permission prompt sonrasi route veya form state'i bozulmaz

### 6. Passage Applicant and Owner Actions E2E

Amac:

- sadece detail acilisi degil, job/tutoring/practice-exam/answer-key tarafindaki gercek owner ve applicant aksiyonlarini dogrulamak

Kritik assertion:

- applicant hesapla apply/save aksiyonu islenir
- owner hesapla review/edit/unpublish veya benzeri owner action kirilmaz
- ilgili liste veya detail durumu mutasyondan sonra tutarli kalir

### 7. Story Management E2E

Amac:

- story viewer disindaki yonetim akislarini kapsamak

Kritik assertion:

- StoryMaker veya StoryMusic girisleri bozuk degil
- deleted story restore/repost/delete forever davranisi beklenen sonucu verir
- highlight ekleme/silme/guncelleme route ve liste state'ini bozmaz

### 8. Settings Round-Trip E2E

Amac:

- settings alt formlarinda save sonrasi geri donus ve UI yansimasini otomatik hale getirmek

Kritik assertion:

- current-user warm seed alanlari dolu gelir
- save sonrasi ilgili header veya profil alani ayni oturumda guncellenir
- ekran tekrar acildiginda veri korunur
- ekstra spinner, flicker veya bos state olmaz

## Test Veri Kontrati

Phase 3 testleri ancak kontrollu veri kontratiyla saglam olur.

Zorunlu prensipler:

- tek bir entegrasyon kullanicisi yerine rol ayrimi kullan:
  - ana test kullanicisi
  - fixture peer chat kullanicisi
  - routeable notification ureten fixture kaynaklari
- testin yazdigi butun metinler belirgin prefix tasiyacak:
  - `E2E_REPLY:`
  - `E2E_CHAT:`
  - `E2E_STORY_REPLY:`
- testler prod kullanici icerigini mutate etmeyecek
- delete testleri yalnizca ayni kosuda olusturulan test verisini temizleyecek
- route hedefi dogrulanacak testlerde deterministic fixture id beklenmeli

## Naming ve Dosya Kurallari

- Gercek mutation yapan ve kullanici akisina inen testler `*_e2e_test.dart` olarak bitsin.
- Daha kisa, teknik ve tek-risk odakli testler `*_smoke_test.dart` olarak bitsin.
- Tek dosyada cok alakasiz risk birikmesin.
- `complete_e2e` yine omurga test olsun ama her derin davranisi oraya yigmayin.

## Artifact ve Gozlemlenebilirlik Kurali

Yeni Phase 3 testleri minimum su ciktilari uretmelidir:

- senaryo ismi
- route dump
- ilgili surface probe
- beklenen id ve gerceklesen id
- fail aninda screenshot best-effort
- gerekiyorsa native player snapshot

Test sonunda sadece "geçti" yeterli sayilmaz.
Neden gectigi artifact'tan okunabilmelidir.

## Phase 3 Done Definition

Bir alan "eklendi" sayilmasi icin su 5 kosulu saglamalidir:

1. gercek kullanici entrypoint'i kullanilir
2. yalnizca ekran acilisi degil, asıl islev tamamlanir
3. sonucu model, route veya visible UI seviyesinde assert edilir
4. test non-destructive veya kontrollu cleanup'li olur
5. artifact/log uzerinden ariza yeri anlasilir

## Sonuc

Bugun sistemin cekirdek nav, playback, ownership ve temel tab traversal omurgasi gucludur.
Fakat comment reply/delete, chat send, notifications deep-link, real single-short entry, story interaksiyonlari, pasaj detail derinligi ve 10-15 dakikalik stress/memory lane tamamlanmadan sistem "tum islevsel derinlikte yesil" sayilmamalidir.
Ek olarak auth/session churn, social graph/safety, post publish persistence, permission matrix, story management ve settings round-trip hattı da tamamlanmadan sistem operasyonel olgunluk acisindan tam sayilmamalidir.

Bu dokuman, o kalan Phase 3 alanlarini kanonik backlog ve kabul kontrati olarak tanimlar.
