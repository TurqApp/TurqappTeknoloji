# Playback Intelligence Phase 1 Cache Ownership

Bu dokuman, mevcut TurqApp repo yapisinda cache katmanlarinin sahipligini ve okuma sirasini netlestirir. Faz 1 kapsami icinde yeni downloader ya da yeni storage engine eklemez.

## 1. Ownership Matrix

### Current User Summary
- Owner: `/Users/turqapp/Desktop/TurqApp/lib/Services/current_user_service.dart`
- Primary in-memory source: `CurrentUserService._currentUser` + `currentUserRx`
- Persistent local source: `SharedPreferences` (`cached_current_user`)
- Firestore root cache bridge: `UserRepository.getUserRaw(... cacheOnly: true)`
- Canonical remote source: `users/{uid}` root doc + subdoc merge zinciri

Okuma sirasi:
1. memory
2. shared prefs
3. Firestore cache
4. server

Yazma kurali:
- Current user degisikligi once `CurrentUserService` uzerinden publish edilir
- Ardindan `UserRepository.seedCurrentUser(...)` ile profile summary cache'i beslenir

### User Profile Summary
- Owner: `/Users/turqapp/Desktop/TurqApp/lib/Core/Services/user_profile_cache_service.dart`
- Primary in-memory source: `_memory`
- Persistent local source: `SharedPreferences` (`user_profile_cache_v2`)
- Firestore local source: `GetOptions(source: Source.cache)`
- Canonical remote source: `users/{uid}` doc

Okuma sirasi:
1. memory
2. Firestore cache
3. server

Not:
- `SharedPreferences` sadece `UserProfileCacheService` kendi persistence'i icin kullanilir
- UI dogrudan bu key'leri okumaz

### Profile Posts Buckets
- Owner: `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/profile_repository.dart`
- Primary in-memory source: `ProfileRepository._memory`
- Persistent local source: `ProfilePostsCacheService`
- Canonical remote source: `Posts` sorgulari

Okuma sirasi:
1. memory
2. shared prefs bucket cache
3. server and cache query

### Image Cache
- Owner: `/Users/turqapp/Desktop/TurqApp/lib/Core/Services/turq_image_cache_manager.dart`
- Role: avatar / kapak / feed image dosya cache'i
- Canonical source degil; sadece binary asset cache

### Video Segment Cache
- Owner: `/Users/turqapp/Desktop/TurqApp/lib/Core/Services/SegmentCache/cache_manager.dart`
- Fetch boundary: `/Users/turqapp/Desktop/TurqApp/lib/Core/Services/SegmentCache/hls_proxy_server.dart`
- Prefetch execution: `/Users/turqapp/Desktop/TurqApp/lib/Core/Services/SegmentCache/prefetch_scheduler.dart`
- Canonical source: HLS CDN

## 2. Source of Truth Rules

- `CurrentUserService` current user ekranlari icin tek authoritative runtime kaynaktir.
- `UserProfileCacheService` diger kullanici summary'leri icin authoritative local-first kaynaktir.
- `ProfileRepository` profile post bucket cache'in sahibidir.
- `TurqImageCacheManager` ve `SegmentCacheManager` binary cache'tir; metadata source-of-truth degildir.

## 3. Runtime Guard Rules

- Current user verisi ile profile summary verisi ayni anda yazilacaksa:
  - once `CurrentUserService`
  - sonra `UserRepository.seedCurrentUser`
- UI, `SharedPreferences` key'lerini dogrudan source-of-truth gibi kullanmaz.
- `forceServer` sadece stale duzeltme ve manuel refresh icin kullanilir.
- `cacheOnly` ag kapali veya korumaci okuma yoludur; normal akisin yerine gecmez.

## 4. Faz 1 Siniri

Bu fazda:
- yeni native offline downloader yok
- yeni local DB yok
- stream cache ile metadata cache yeniden yazilmiyor

Bu fazda sadece:
- ownership
- read order
- TTL policy
- KPI gorunurlugu
- budget split
netlestirilir.

## 5. Rollout Status

### Tamamlananlar
- `CurrentUserService -> UserRepository -> UserProfileCacheService` sahiplik zinciri uygulamada aktif.
- `ProfileRepository` profile post bucket owner olarak aktif.
- `TypesenseMarketSearchService` artik `memory + disk + TTL` cache owner.
- `TypesenseEducationSearchService` artik `memory + disk + TTL` cache owner.
- `TypesensePostService` artik post card metadata icin `memory + disk + TTL` cache owner.
- `AgendaShuffleCacheService` feed shuffle buffer owner olarak aktif.
- `StoryRepository` story row + deleted stories invalidation owner olarak aktif.

### Kismi Tamamlananlar
- `Feed/Agenda` veri omurgasi repository-first; controller tarafinda kalan `userPrivacy/deactivated` map'leri owner-level persistence degil, UI-oturum memoization seviyesinde.
- `TopTags`, `StoryMusic`, `Booklet`, `Scholarship`, `Tutoring` gibi owner repository/service'ler ayri ayri dogru yonde; ortak metric raporlamasi her owner'da ayni seviyede degil.

### Henuz Tamamlanmayanlar
- Ek bir zorunlu mimari tasima yok.
- Kalan isler operasyonel izleme ve ilerideki owner'lara ayni standardi kopyalamaktan ibaret.

## 6. Sonraki Is Sirasi

1. Yeni owner eklendiginde bu dokumandaki tablo ve metric standardina uydur.
2. UI-oturum memoization'larini veri cache'i gibi buyutmeme kuralini koru.

## 7. Invalidation Tablosu

### Current User Summary
- Tetikleyici: profil duzenleme, avatar degisimi, nickname degisimi, hesap gizliligi degisimi
- Temizlenecek owner: `CurrentUserService`
- Ardil is: `UserRepository.seedCurrentUser(...)` ile profile summary cache'ini besle

### User Profile Summary
- Tetikleyici: herhangi bir kullanici profil alaninin degismesi
- Temizlenecek owner: `UserProfileCacheService`
- Ardil is: ilgili ekranlarda sonraki okumayi `preferCache=true` ile yeniden yap

### Profile Posts Buckets
- Tetikleyici: post create, post delete, arsiv durumu degisikligi
- Temizlenecek owner: `ProfileRepository`
- Ardil is: ilgili profil sekmesinde ilk okuma bucket cache'ten, refresh server'dan gelir

### Typesense Market Search
- Tetikleyici: ilan create, edit, delete, ended/published degisikligi
- Temizlenecek owner: `TypesenseMarketSearchService`
- Ardil is: detail refresh `forceRefresh=true`, liste sayfasi normal `preferCache=true`

### Typesense Education Search
- Tetikleyici: burs, is veren, ozel ders, soru bankasi, cikmis soru seti metadata degisikligi
- Temizlenecek owner: `TypesenseEducationSearchService`
- Ardil is: liste ve arama ekrani tekrar acildiginda cache-first, manuel yenilemede force refresh

### Typesense Post Cards
- Tetikleyici: post update, reshare sync, moderation/deleted/archived degisikligi
- Temizlenecek owner: `TypesensePostService`
- Ardil is: `PostRepository.fetchPostCardsByIds(...)` sonraki okumada yeni hit'i yazar

### Agenda Shuffle Buffer
- Tetikleyici: feed refresh, yeni feed penceresi, shuffle pipeline reset
- Temizlenecek owner: `AgendaShuffleCacheService`
- Ardil is: agenda ilk boya pool/cache-first ile tekrar dolar

### Story Row ve Deleted Stories
- Tetikleyici: soft delete, restore, repost, expire cleanup
- Temizlenecek owner: `StoryRepository.invalidateStoryCachesForUser(...)`
- Ardil is: story row ve deleted stories sonraki okumada repository owner'dan yeniden kurulur

## 8. Metric Standardi

Her owner icin asgari gorunurluk dili ayni olmalidir:
- `memory_hit`
- `disk_hit`
- `network_miss`
- `force_refresh`
- `cache_only_hit`
- `stale_drop`

Yorum kurali:
- `memory_hit`: owner bellekte taze veri buldu
- `disk_hit`: owner kalici cache'ten taze veri buldu
- `network_miss`: cache karsilamadi ve ag cagrisi gerekti
- `force_refresh`: kullanici veya servis stale duzeltme icin cache'i atladi
- `cache_only_hit`: ag kapali korumaci okumada cache veri verdi
- `stale_drop`: stale veri bulundu ama TTL disi oldugu icin servis etmedi

Raporlama kurali:
- Owner seviyesinde adlandirilir
- Controller seviyesinde ikinci bir cache metriği uretilmez
- UI-oturum memoization sayaclari owner metric'i gibi yorumlanmaz
