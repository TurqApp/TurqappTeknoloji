# Faz 2 Market Counter Server Pipeline

Uretim tarihi: `2026-03-28`

## Kapsam

Bu artifact, `F2-004` kapsaminda market root sayaçlari icin gercek server ownership pipeline'inin uygulandigini kaydeder.

Kapsam:

- `favoriteCount`
- `offerCount`
- `reviewCount`
- `averageRating`
- `lastOfferAt`
- `viewCount`

## Uygulanan server ownership hattı

Functions:

- `onMarketFavoriteCreate`
- `onMarketFavoriteDelete`
- `onMarketOfferCreate`
- `onMarketReviewWrite`
- `recordMarketViewBatch`
- `aggregateMarketViewShards`
- `backfillMarketCounters`

Rules:

- owner update denylist:
  - `viewCount`
  - `favoriteCount`
  - `offerCount`
  - `reviewCount`
  - `averageRating`
  - `lastOfferAt`
  - `_serverCounters`
- create sirasinda forged non-default counter payload reddi

Client:

- `MarketRepository.incrementViewCount(...)` artik `recordMarketViewBatch` callable'ini cagirir
- UI optimistic davranis korunur; callable hatasi local sayaci patlatmaz

## Neler degisti

### Favorites

- `marketStore/{itemId}/favorites/{uid}` create/delete event'i root `favoriteCount` alanini server tarafinda guncelliyor

### Offers

- `marketStore/{itemId}/offers/{offerId}` create event'i root `offerCount` alanini artiriyor
- ayni anda `lastOfferAt` alanini `max(existing, createdAt)` mantigiyla guncelliyor

### Reviews

- `marketStore/{itemId}/Reviews/{uid}` write event'i root `reviewCount` ve `averageRating` alanlarini guncelliyor
- `_serverCounters.ratingTotal` teknik alanı ile tam koleksiyon taramasi olmadan ortalama hesaplanıyor

### Views

- istemci root `viewCount` yazmiyor
- `recordMarketViewBatch` shard'a yaziyor
- `aggregateMarketViewShards` scheduled reducer dirty shard'lari root `viewCount` alanina topluyor

### Backfill

- `backfillMarketCounters` admin callable'i mevcut root market belgelerini favorites/offers/reviews alt koleksiyonlarindan yeniden hesaplayip normalize ediyor
- `viewCount` mevcut root degerini seed olarak koruyor

## Teknik sonuc

- market root sayaçlari artik client-owned degil
- root belge okunur read model olarak kaldi
- event source alt koleksiyonlarda
- Typesense root `marketStore` dokumanini okumaya devam ediyor; ek indeks migrasyonu gerekmedi

## Dogrulama

Komutlar:

- `npm run build`
- `node --test functions/tests/unit/marketCounters.test.js`
- `npm run test:rules`
- `dart analyze --no-fatal-warnings lib/Core/Repositories/market_repository_library.dart lib/Core/Repositories/market_repository_action_part.dart`
- `ARCHITECTURE_ARTIFACT_DIR=/tmp/f2_004_arch bash scripts/check_architecture_guards.sh --against HEAD --files lib/Core/Repositories/market_repository_library.dart,lib/Core/Repositories/market_repository_action_part.dart`

Sonuclar:

- functions build: `gecti`
- market counter unit tests: `4/4`
- firestore/storage rules paketi: `92/92`
- dart analyze: `gecti`
- architecture guard: `gecti`

## Hukum

`F2-004` kabul edildi:

- market sayaçlari icin server-owned pipeline kuruldu
- owner/client root counter mutasyonu kapatildi
- view path icin callable + shard + reducer hattı aktiflestirildi
- backfill admin runner eklendi
- `RISK-006` ve `ADV-001` bu implementasyonla kapandi
