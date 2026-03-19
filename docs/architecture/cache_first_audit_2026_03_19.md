# TurqApp Cache-First Mimari Denetimi

Tarih: 19 Mart 2026

## Sonuç

TurqApp'te cache kullanımı var, ancak uygulama genelinde tek ve tutarlı bir `cache-first` mimari yok.

İlk değerlendirmedeki ana yön doğruydu, fakat eksik kalan kritik gerçekler var:

- Sorun sadece cache mantığının controller'larda dağılmış olması değil.
- Sorun aynı zamanda mevcut snapshot katmanlarının user-scope, TTL, source ve eligibility açısından eksik tanımlanmış olması.
- Repo'da parça parça çalışan `snapshot-first`, `cache-first`, `pool-first`, `Firestore-cache-first` ve `SWR-benzeri` akışlar var; fakat bunlar tek kontrata bağlanmış değil.
- `Feed`, `Short` ve `Explore` aynı tip "renderable candidate snapshot" problemine sahip.
- `Job` yüzeyinde tek bir cache hattı yok; `TypesenseEducationSearchService` ile `JobRepository` ayrı cache çizgileri oluşturuyor.
- `Notifications` hâlâ büyük ölçüde Firestore local cache davranışına yaslanıyor; uygulamanın kendi ordered snapshot katmanı yok.
- `CurrentUser` güçlü bir örnek, ama bu kalite diğer ana yüzeylere yayılmış değil.

Doğru karar:

- `CurrentUser`, `Feed`, `Short`, `Explore`, `Job`, `Notifications` için ortak bir `snapshot-first + silent sync + stale-while-revalidate` kontratı kurulmalı.
- Cache mantığı controller içinde dağınık kalmamalı; repository, candidate assembler ve scoped snapshot store katmanına taşınmalı.
- `Feed`, `Short` ve `Explore` için "ham veri cache'i" değil, doğrudan render edilebilir aday snapshot tutulmalı.
- Ağ koptuğunda listeyi boşaltan değil, son başarılı snapshot'ı koruyan davranış standart hale getirilmeli.
- Snapshot store mutlaka kullanıcı scope'u taşımalı; global, user-agnostic havuz mantığı ana yüzeyler için yeterli değil.

Bu, TurqApp için doğru yön. Tamamen stream-first kalmak yanlış; tamamen offline-first yapmak da yanlış. Doğru model: `cache-first, sync-backed`.

## Lider Uygulamalardan Çıkan Ders

Meta News Feed tarafında istemci tarafında yeniden sıralama, persistent cache ve "medyası hazır olmayan içeriği aşağı itme" mantığını açıkça anlatıyor. Temel prensip: kullanıcı güçlü ağ bağlantısına bağımlı olmadan anlamlı içerik görmeli.

Instagram Explore tarafında çok aşamalı bir retrieval/ranking/reranking yapısı var. En kritik ders: aday havuzu ile nihai sıralama ayrılıyor ve cache/pre-computation ağır biçimde kullanılıyor.

X tarafında aday kaynakları, ranking, heuristics ve final mixing net ayrılmış. Yani reklam, önerilen kullanıcı ve içerik karıştırma en sonda yapılıyor.

TikTok tarafında tekrar eden içerik, aynı creator, aynı sound ve aşırı tekrar riskine karşı diversity ve refresh mantığı ayrı bir ürün katmanı olarak ele alınıyor.

TurqApp için çıkarım:

- Önce adayları üret
- Sonra eligibility filtrelerini uygula
- Sonra client-side rerank yap
- En son promo slotlarını karıştır
- Ağ zayıfsa son başarılı renderable snapshot üzerinden çalış

## Repo İncelemesinden Çıkan Gerçek Durum

### 1. Güçlü Taraflar

#### Current user

`lib/Services/current_user_service.dart`
`lib/Services/current_user_service_cache_part.dart`

Bu servis, uygulamadaki en olgun cache-first örneği.

- `SharedPreferences` cache var
- memory cache var
- user-scope cache key mantığı var
- önce cache yükleyip sonra Firebase sync başlatıyor
- sync arka planda çalışıyor
- TTL ve cache key mantığı tanımlı
- logout sırasında kendi kullanıcı scope'lu cache'lerini temizliyor

Bu servis, yeni ortak veri kontratı için referans alınmalı.

#### Feed

`lib/Modules/Agenda/agenda_controller_loading_part.dart`
`lib/Core/Repositories/post_repository.dart`

Feed tarafı sanıldığından daha gelişmiş.

- `quick fill from pool`
- `cacheOnly` ile ilk boya hazırlık
- `persistWarmLaunchCache`
- ağ hatasında eski listeyi geri koyma
- retry/backoff
- birden fazla aday kaynağını birleştirme
- visibility/privacy filtresi uygulama

Yani feed tarafında ana fikir doğru. Ama uygulama hâlâ controller-merkezli ve snapshot store katmanı user-scope açısından eksik.

#### Job

`lib/Modules/JobFinder/job_finder_controller.dart`
`lib/Core/Repositories/job_repository.dart`
`lib/Core/Services/typesense_education_service.dart`
`lib/Core/Services/silent_refresh_gate.dart`

Job tarafında:

- Typesense sonucu disk + memory cache'e yazılıyor
- cache varsa önce hızlı liste gösteriliyor
- sonra sessiz tam refresh yapılıyor
- konum sıralaması sonradan geliyor

Bu doğru yön. Fakat aynı yüzey iki ayrı cache hattına bölünmüş durumda:

- home bootstrap `TypesenseEducationSearchService` üstünden dönüyor
- detay ve bazı ek okumalar `JobRepository` üstünden dönüyor
- refresh gate process-memory tabanlı; uygulama yeniden açılınca süre bilgisi kayboluyor

Yani burada tek sorun standardizasyon eksikliği değil, veri cache çizgisinin bölünmüş olması.

#### Notifications

`lib/Core/Repositories/notifications_repository.dart`
`lib/Modules/InAppNotifications/in_app_notifications_controller.dart`

Bildirim tarafında:

- önce Firestore cache okunuyor
- cache stream dinleniyor
- sonra yeni head değişirse server'dan yeni bildirimler merge ediliyor
- optimistic read/delete davranışı var

Bu iyi bir başlangıç. Ama hâlâ Firestore local cache davranışına fazla bağımlı ve uygulamanın kendi ordered snapshot katmanı yok.

#### Explore

`lib/Modules/Explore/explore_controller.dart`

İlk metinde eksik kalan önemli yüzeylerden biri bu.

- pool'dan hızlı doldurma var
- privacy filtresi var
- background cleanup var
- candidate list mantığı var

Bu yüzden `Explore`, mimari programın dışında bırakılmamalı. `Feed` ve `Short` ile aynı ailede düşünülmeli.

### 2. Zayıf Taraflar

#### En kritik açık: mevcut snapshot store user-scoped değil

`lib/Core/Services/IndexPool/index_pool_store.dart`

Bugünkü ana havuz katmanı için temel sorunlar:

- tek global `pool.json` dosyası kullanılıyor
- user-scope yok
- audience-scope yok
- `Feed`, `Short`, `Explore` aynı genel store yaklaşımını paylaşıyor
- logout sırasında bu havuz temizlenmiyor

Bu yüzden ana yüzeylerde "persistent snapshot var" demek teknik olarak eksik bir ifade. Var olan şey, tam anlamıyla güvenli ve doğru scope'lanmış bir snapshot store değil; daha çok global bir warm-start pool.

#### TTL davranışı sandığından daha zayıf

`lib/Core/Services/IndexPool/index_pool_store.dart`
`lib/Modules/Agenda/agenda_controller_loading_part.dart`
`lib/Modules/Explore/explore_controller.dart`

`IndexPoolStore` içinde TTL tanımlı olsa da:

- `allowStale: true` kullanılan çağrılarda per-kind TTL fiilen devre dışı kalıyor
- `Feed` hızlı açılışında stale pool kabul ediliyor
- `Explore` hızlı açılışında stale pool kabul ediliyor

Yani uygulama bazı yüzeylerde kontrollü snapshot yaşı ile değil, "elde ne varsa getir" mantığıyla açılıyor.

Bu, `snapshot-first` için yeterli değil. Doğru model `scoped snapshot + explicit freshness metadata` olmalı.

#### Short tarafı en zayıf yüzey

`lib/Core/Repositories/short_repository.dart`
`lib/Modules/Short/short_controller.dart`
`lib/Modules/Short/short_view.dart`

Kritik sorunlar:

- `ShortRepository` sayfa bazlı Firestore sorgusu yapıyor
- sonra ağır client-side filtre uygulanıyor
- sayfa boşalınca içerik azalmış gibi görünüyor
- persistent "eligible short snapshot" yok
- veri katmanı ile playback/bootstrap katmanı birbirine fazla bağlı
- quick-fill yolunda eligibility kontratı tam korunmuyor

Özellikle eksik kalan kritik nokta şu:

- normal pagination akışı privacy/follow eligibility uyguluyor
- ama pool'dan hızlı doldurma akışı sadece post geçerliliğini doğruluyor
- yani short warm-start bazen gerçekten eligible olmayan içeriği de açılışta listeye alabilir

Bu yüzden short tarafında:

- bazen 20 short yerine 3-5 short görülüyor
- bazen pagination erken bitiyor
- bazen ilk aktif video kararsızlaşıyor

Ve ilk aktif video kararsızlığının bir kısmı veri katmanından değil, view bootstrap kararından geliyor:

- `ShortView` bazı durumlarda açılış index'ini `1`e itiyor
- bu da ilk aktif video davranışını veri akışından bağımsız olarak kararsızlaştırabiliyor

Sorun sadece player değil; veri kontratı ve bootstrap kontratı birlikte zayıf.

#### Cache kuralları merkezi değil

Repo genelinde:

- farklı TTL'ler
- farklı cache medium'ları
- farklı fallback kuralları
- farklı hata davranışları
- farklı source öncelikleri
- farklı scope varsayımları

Yani aynı tip sorunlar her modülde tekrar çözülüyor.

#### Repo'da zaten bir SWR iskeleti var, ama hedef kontrat için yetersiz

`lib/Core/Services/swr_controller.dart`

İlk metinde eksik kalan bir diğer önemli nokta:

- repo'da ortak bir `SWRController` tabanı zaten var
- fakat bu sınıf `CachedResource<T>` seviyesinde metadata taşımıyor
- refresh sırasında listeyi temizliyor
- `snapshotAt`, `source`, `isStale`, `hasLiveError` gibi bilgileri sunmuyor

Yani burada sıfırdan yeni fikir icat etmekten çok, mevcut SWR tabanını ya kaldırmak ya da ciddi biçimde genişletmek gerekiyor.

#### Controller'lar fazla sorumluluk taşıyor

Özellikle:

- `AgendaController`
- `ShortController`
- `JobFinderController`
- `ExploreController`

veri çekme, filtreleme, cache, retry, ranking, playback, UI state, telemetry aynı yerde toplanmış.

Bu, kırıkların tekrar etmesine neden oluyor.

## Bugünkü Yapının Daha Net Teşhisi

Bugünkü yapı için en doğru kısa tanım şu:

- cache var
- snapshot benzeri katmanlar var
- ama bunlar scope, freshness, source ve eligibility açısından standart değil

Özellikle üç ayrı problem aynı anda var:

1. Store problemi
- snapshot store user-scoped değil
- freshness kuralları yüzeyler arasında tutarlı değil

2. Contract problemi
- UI aynı anda `empty`, `stale`, `refreshing`, `offline`, `live-error` ayrımını standart biçimde alamıyor

3. Assembly problemi
- `Feed`, `Short`, `Explore` için ham sorgu sonucu ile render edilebilir aday listesi birbirine karışıyor

## TurqApp İçin Doğru Hedef Mimari

### A. Ortak veri kontratı

Her ana yüzey için aynı sözleşme kullanılmalı:

```dart
enum SnapshotSource {
  memory,
  scopedDisk,
  firestoreCache,
  server,
}

class CachedResource<T> {
  final T? data;
  final bool hasLocalSnapshot;
  final bool isRefreshing;
  final bool isStale;
  final bool hasLiveError;
  final DateTime? snapshotAt;
  final SnapshotSource source;
}
```

Bu model şunları zorunlu kılar:

- önce snapshot göster
- sonra sessiz refresh başlat
- hata olursa snapshot'ı koru
- UI `empty`, `stale`, `refreshing`, `offline` ve `live-error` durumlarını ayırabilsin

### B. Üç katmanlı veri yapısı

Her ana yüzey için:

1. `MemoryCache`
2. `ScopedSnapshotStore`
3. `LiveSource`

akışı olmalı.

Yani:

- Memory: aynı oturumda en hızlı dönüş
- Scoped snapshot: uygulama açılışındaki ilk boya
- Live source: server/Firestore/Typesense güncellemesi

Buradaki kritik ek karar:

- `ScopedSnapshotStore` mutlaka `userId` veya uygun audience scope taşımalı
- store `surfaceKey`, `snapshotAt`, `schemaVersion`, `generationId` gibi metadata saklamalı

### C. Aday üretim ile render ayrılmalı

Bu özellikle `Feed`, `Short` ve `Explore` için gerekli.

Doğru yapı:

1. raw candidate source
2. eligibility filter
3. local rerank
4. promo mixing
5. renderable snapshot persistence

Yani snapshot'a ham Firestore sonucu değil, gerçekten gösterilebilir liste yazılmalı.

### D. Stream kopunca boş liste olmamalı

Özellikle:

- feed
- notifications
- job
- explore

tarafında canlı kaynak başarısız olduğunda:

- eski snapshot kalmalı
- üstte sessiz refresh göstergesi olabilir
- ama liste sıfırlanmamalı

### E. Warm-start pool ile gerçek snapshot ayrılmalı

Bugünkü `IndexPoolStore` mantığı tamamen çöpe atılmak zorunda değil.

Ama doğru kullanım şu olmalı:

- warm-start pool kısa ömürlü performans katmanı olabilir
- ana ürün kontratı bunun üstüne kurulamaz
- asıl veri kontratı user-scoped snapshot store üzerinde olmalı

## Yüzey Bazlı Doğru Kararlar

### 1. Feed

Karar:

- Feed `snapshot-first` çalışmalı
- ilk açılışta user-scoped `feed_snapshot` gösterilmeli
- canlı veri arkada merge edilmeli
- medya hazır olmayan post aşağı itilip hazır olan öne çekilmeli
- reklam/önerilen kişi gibi slotlar ranking sonrası eklenmeli

Yapılmaması gereken:

- listeyi yenilemeden önce boşaltmak
- promo slotlarını veri akışının parçası gibi görmek
- controller içinde ranking + cache + UI birlikte yürütmek
- tek başına global `IndexPoolStore`u kalıcı snapshot yerine koymak

Önerilen teknik yön:

- `FeedSnapshotRepository`
- `FeedCandidateAssembler`
- `FeedClientMixer`

Not:

- `Feed` tarafındaki problem sadece controller şişmesi değil
- burada zaten çok kaynaklı candidate assembly var
- bu yüzden çözüm "her şeyi tek repository'ye taşı" değil, katmanları net ayırmak

### 2. Short

Karar:

- Short için ayrı `eligible short snapshot` tutulmalı
- playback cache ile veri cache ayrılmalı
- sayfa bazlı sorgu sonrası client-side ağır filtre yerine, mümkün olan filtre server tarafına alınmalı
- boş sayfa geldi diye pagination bitmemeli
- ilk aktif video bootstrap'i veri akışından bağımsız sade bir state machine ile yürümeli

En önemli karar:

- `ShortRepository` ham post döndürmemeli; mümkün olduğunca "eligible short candidate" döndürmeli
- quick-fill hattı ile normal pagination hattı aynı eligibility sözleşmesini uygulamalı

Önerilen teknik yön:

- `ShortSnapshotStore`
- `ShortEligibilityService`
- `ShortPlaybackCoordinator`

Bu yüzeyde iki ayrı iş kalemi açıkça ayrılmalı:

- veri kontratı düzeltmesi
- playback/bootstrap state machine düzeltmesi

### 3. Explore

Karar:

- `Explore` artık resmi olarak cache-first programın içine alınmalı
- `Feed` ile aynı ailede candidate snapshot mantığı kullanılmalı
- vertical playable candidate list snapshot'ı tutulmalı
- privacy ve deactivated account eligibility snapshot yazılmadan önce uygulanmalı

Önerilen teknik yön:

- `ExploreSnapshotRepository`
- `ExploreCandidateAssembler`
- `ExploreClientMixer`

### 4. Job

Karar:

- şu anki staged bootstrap korunmalı
- ama `TypesenseEducationSearchService` cache'i tek başına yeterli sayılmamalı
- `JobRepository` ve Typesense cache hattı tek kontratta birleştirilmeli
- ana ekran için ayrı `job_home_snapshot` tutulmalı
- konum ve mesafe yeniden sıralaması ilk boya sonrasına kalmalı
- silent refresh TTL process-memory'de kalmamalı

En iyi yön zaten burada başlıyor. Sadece standardize edilmekten fazlası gerekiyor; aynı yüzeydeki cache çizgileri birleştirilmeli.

### 5. Notifications

Karar:

- Firestore local cache tek snapshot katmanı sayılmamalı
- uygulamanın kendi sıralanmış bildirim snapshot'ı tutulmalı
- cache stream + new head merge korunmalı
- read/delete optimistic update devam etmeli

Önerilen teknik yön:

- `NotificationsSnapshotStore`
- `NotificationsSyncEngine`

### 6. CurrentUser

Karar:

- bu servis yeni ortak kontratın temel örneği olmalı
- diğer yüzeyler bu pattern'e yaklaştırılmalı
- özellikle user-scope, TTL, fallback ve silent sync davranışı referans alınmalı

## Ne Cache-First Olmamalı

Her şeyi cache-first yapmak da doğru değil.

Tam canlı kalması gerekenler:

- aktif chat mesaj akışı
- typing/presence
- call/session state
- moderation ve güvenlik açısından anlık karar gereken bazı alanlar

Bu yüzeyler `stream-first`, ama yine de son iyi snapshot'ı tutabilir.

## Önce Düzeltilmesi Gereken Somut Temel Kusurlar

Bu denetimden çıkan en acil teknik kusurlar:

1. `IndexPoolStore` user-scoped hale getirilmeli veya ana snapshot store görevinden çıkarılmalı.
2. `Feed` ve `Explore` hızlı açılışında stale kabul kuralları açık ve sınırlı hale getirilmeli.
3. `Short` quick-fill eligibility hattı normal pagination ile aynı kurallara bağlanmalı.
4. `ShortView` ilk aktif video bootstrap kuralı veri kontratından ayrıştırılmalı.
5. `Job` için Typesense cache ile repository cache tek veri sözleşmesine bağlanmalı.
6. Mevcut `SWRController` ya genişletilmeli ya da yeni kontrat lehine bırakılmalı.

## En Doğru Uygulama Sırası

### Faz 0

- `ScopedSnapshotStore` arayüzü
- `CachedResource<T>` modeli
- ortak hata/sync durum modeli
- mevcut `SWRController` kararının netleştirilmesi
- `IndexPoolStore`un rolünün yeniden tanımlanması

Neden:

- bu temel katman netleşmeden yüzey migrasyonları tekrar dağılır
- aksi halde eski ve yeni cache sistemleri yan yana yaşayıp karmaşıklığı artırır

### Faz 1

- `Notifications` ve `Job` migrasyonu

Neden:

- daha düşük risk
- mevcut yapı zaten kısmen hazır
- hızlı ürün etkisi verir

### Faz 2

- `Feed` ve `Explore` migrasyonu

Burada:

- candidate cache
- eligibility
- client rerank
- promo mixing ayrımı

kurulmalı

Bu iki yüzey birlikte ele alınmalı çünkü aynı candidate snapshot problem ailesindeler.

### Faz 3

- `Short` veri + playback ayrıştırması

Bu son faz olmalı çünkü en hassas ve regresyon riski en yüksek yüzey bu.

## Net Teknik Kararlar

TurqApp için alınması gereken kararlar:

1. Cache katmanı controller'dan repository/snapshot store katmanına çekilecek.
2. Tüm ana yüzeyler `snapshot-first + silent sync` davranışıyla açılacak.
3. Ağ hatasında eldeki liste korunacak; boş state'e geri düşülmeyecek.
4. `Feed`, `Short` ve `Explore` için ham belge cache'i değil, render edilebilir aday snapshot'ı tutulacak.
5. Promo slotları ranking sonrası mix edilecek.
6. `Short` playback state ile short veri snapshot'ı birbirinden ayrılacak.
7. Snapshot store user-scoped olacak; global warm pool tek başına yeterli sayılmayacak.
8. Refresh/staleness kararları kalıcı metadata ile verilecek; sadece process-memory gate ile değil.
9. Her yüzey için standart metrik toplanacak:
   - cold start snapshot hit
   - first contentful paint
   - stale snapshot age
   - live sync success/fail
   - empty-after-filter rate
   - snapshot scope mismatch rate

## Kısa Teşhis

Bugünkü yapı:

- cache var
- bazı yüzeylerde iyi fikirler var
- ama mimari düzeyde standart değil
- snapshot katmanları scope ve freshness açısından eksik tanımlı

Olması gereken yapı:

- cache-first
- sync-backed
- scoped-snapshot
- client-reranked

TurqApp için en doğru yön bu.

## Referans Kaynaklar

- Meta, client-side ranking ve persistent cache yaklaşımı:
  https://engineering.fb.com/2016/10/20/networking-traffic/client-side-ranking-to-more-efficiently-show-people-stories-in-feed/
- Meta, Instagram Explore cok asamali retrieval/ranking ve caching:
  https://engineering.fb.com/2023/08/09/ml-applications/scaling-instagram-explore-recommendations-system/
- X, candidate sourcing + ranking + heuristics + mixing:
  https://blog.x.com/engineering/en_us/topics/open-source/2023/twitter-recommendation-algorithm
- TikTok, diversity/repetition kontrolu ve feed refresh mantigi:
  https://newsroom.tiktok.com/introducing-a-way-to-refresh-your-for-you-feed-on-tiktok-sg?lang=en-SG
