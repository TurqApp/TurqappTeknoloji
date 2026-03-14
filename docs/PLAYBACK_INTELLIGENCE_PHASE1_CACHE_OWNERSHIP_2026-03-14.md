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
