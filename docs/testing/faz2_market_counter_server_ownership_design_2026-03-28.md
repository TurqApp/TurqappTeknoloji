# Faz 2 Market Counter Server-Ownership Tasarimi

Uretim tarihi: `2026-03-28`

## Kapsam

Bu artifact, `marketStore/{itemId}` root dokumanindaki turetilmis sayaç ve rating alanlarini server ownership modeline tasimak icin Faz 2 tasarim kararlarini kayda alir.

Kapsamdaki alanlar:

- `viewCount`
- `favoriteCount`
- `offerCount`
- `reviewCount`
- `averageRating`
- `lastOfferAt`

## Mevcut Durum

- `T-006` ile client tarafindaki dogrudan root counter yazim yolu kapatildi.
- Buna ragmen root `marketStore/{itemId}` dokumani hala owner update izni altinda oldugu icin turetilmis alanlar tam server-owned degil.
- `favorite`, `offer` ve `review` olaylari zaten alt koleksiyonlar olarak mevcut:
  - `marketStore/{itemId}/favorites/{uid}`
  - `marketStore/{itemId}/offers/{offerId}`
  - `marketStore/{itemId}/Reviews/{uid}`
- `viewCount` icin su anda kalici event kaynagi yok; istemci yalniz lokal optimistic artis gosteriyor.
- Typesense market index'i root `marketStore` alanlarini okuyarak besleniyor; bu nedenle turetilmis sayilar yine root dokumana materyalize edilmek zorunda.

## Temel Tasarim Karari

Prensip:

- root `marketStore/{itemId}` dokumani, bu alanlar icin "read model" olacak
- istemci bu alanlari dogrudan yazmayacak
- owner da bu alanlari guncelleyemeyecek
- gercek kaynak, alt koleksiyon eventleri ve server-side shard toplamlari olacak

## Alan Bazli Ownership Matrisi

| Alan | Kanonik event kaynagi | Server yazim modeli | Not |
| --- | --- | --- | --- |
| `favoriteCount` | `favorites/{uid}` create/delete | trigger ile increment/decrement | bir kullanici = bir favorite dokumani |
| `offerCount` | `offers/{offerId}` create | trigger ile increment | `offer` silinmedigi icin toplam dokuman sayisi yeterli |
| `lastOfferAt` | `offers/{offerId}.createdAt` | trigger ile `max(existing, createdAt)` | offer sayaci ile ayni hatta guncellenir |
| `reviewCount` | `Reviews/{uid}` create/delete | trigger ile count guncelleme | update rating degistirse de count sabit kalir |
| `averageRating` | `Reviews/{uid}.rating` | trigger ile `ratingTotal / reviewCount` | root'a okunur ortalama yazilir |
| `viewCount` | yeni `marketStore/{itemId}/_viewShards/{shardId}` | callable + scheduled aggregation | yuksek frekansli write icin shard gerekli |

## Secilen Server Modelleri

### 1. Favorites

- Kaynak: `marketStore/{itemId}/favorites/{uid}`
- Trigger:
  - `onCreate` -> `favoriteCount + 1`
  - `onDelete` -> `favoriteCount - 1`
- Ek kural:
  - ayni kullanici icin tekrarli favorite dokumani olmayacagi icin dedupe dogal olarak koleksiyon yapisinda saglanir

### 2. Offers

- Kaynak: `marketStore/{itemId}/offers/{offerId}`
- Trigger:
  - yalniz `onCreate` -> `offerCount + 1`
  - ayni anda `lastOfferAt = max(root.lastOfferAt, offer.createdAt)`
- Gerekce:
  - mevcut akista `offer` silinmiyor
  - `accepted/rejected` status degisimleri offer sayisini degistirmez

### 3. Reviews

- Kaynak: `marketStore/{itemId}/Reviews/{uid}`
- Root'ta ek server-only alan:
  - `_serverCounters.ratingTotal`
- Trigger:
  - `onCreate` -> `reviewCount + 1`, `ratingTotal + rating`
  - `onUpdate` -> `ratingTotal += (newRating - oldRating)`
  - `onDelete` -> `reviewCount - 1`, `ratingTotal - oldRating`
- Root read model:
  - `averageRating = reviewCount == 0 ? null : round1(ratingTotal / reviewCount)`

Bu tercih, her review degisiminde tum alt koleksiyonu tarama ihtiyacini kaldirir.

### 4. Views

- Kaynak: yeni shard koleksiyonu:
  - `marketStore/{itemId}/_viewShards/{0..N-1}`
- Write modeli:
  - yeni callable `recordMarketViewBatch`
  - istemci tekil root update yerine shard'a `FieldValue.increment(...)` yazdirir
- Aggregation modeli:
  - scheduled reducer shard toplamini root `viewCount` alanina yazar
  - ayni hatta dirty shard temizligi / updatedAt pencere mantigi kullanilir
- Gerekce:
  - `view` olayi yuksek frekansli olabilir
  - tek root dokumanina event-bazli yazim contention uretir
  - repo icinde halihazirda `functions/src/counterShards.ts` benzeri bir ornek var

## Root Dokuman Contract'i

F2-004 sonunda root `marketStore/{itemId}` icin beklenti:

- client tarafinda okunur alanlar:
  - `viewCount`
  - `favoriteCount`
  - `offerCount`
  - `reviewCount`
  - `averageRating`
  - `lastOfferAt`
- server-only teknik alanlar:
  - `_serverCounters.ratingTotal`
  - `_serverCounters.version`
  - `_serverCounters.backfilledAt`

Not:

- server-only alanlar Typesense'a tasinmak zorunda degil
- Typesense root dokumandan yalniz okunur alanlari almaya devam eder

## Rules ve Client Siniri

F2-004 implementasyonunda zorunlu kural:

- `marketStore/{itemId}` owner update akisi bu turetilmis alanlari degistirememeli
- asagidaki alanlar server-owned denylist olarak ele alinmali:
  - `viewCount`
  - `favoriteCount`
  - `offerCount`
  - `reviewCount`
  - `averageRating`
  - `lastOfferAt`
  - `_serverCounters`

Gecis notu:

- create aninda sifir/default degerler hala tolere edilebilir
- ama update sirasinda istemcinin bu alanlari degistirmesi reddedilmeli

## Backfill Tasarimi

F2-004 oncesi veya deploy ile birlikte tek seferlik backfill gerekir.

Backfill adimlari:

1. Her `marketStore/{itemId}` icin `favorites`, `offers`, `Reviews` alt koleksiyonlarini oku.
2. `favoriteCount`, `offerCount`, `reviewCount`, `averageRating`, `lastOfferAt` degerlerini turet.
3. `ratingTotal` degerini hesaplayip `_serverCounters.ratingTotal` altina yaz.
4. Root dokumana `version` ve `backfilledAt` damgasi yaz.
5. `viewCount` icin mevcut root deger korunur; yeni shard modeli devreye girdikten sonra reducer artik bu alanin sahibi olur.

Neden `viewCount` farkli:

- gecmis view olaylari alt koleksiyonda tutulmadigi icin tam geriye donuk yeniden sayim mumkun degil
- bu nedenle `viewCount` icin:
  - mevcut root deger seed olarak korunur
  - yeni shard reducer bundan sonraki artislarin sahibi olur

## Rollout Sirasi

Onerilen resmi sira:

1. Backfill script'i hazirla
2. Favorites/offers/reviews triggerlarini deploy et
3. Owner update rules denylist'ini ekle
4. `recordMarketViewBatch` callable + view shard reducer'ini deploy et
5. Client view yazim yolunu callable/shard modeline bagla
6. Emulator ve production-benzeri smoke ile count drift gozlemi yap

## Rollback Yaklasimi

Rollback hedefi security yolunu tekrar acmadan sistemi stabil tutmaktir.

- trigger/callable deploy'u geri alinabilir
- root dokumandaki son server snapshot okunmaya devam eder
- istemcinin eski root counter yazim yolu geri acilmaz
- sorun sadece `view` aggregation hattindaysa:
  - shard reducer durdurulur
  - root `viewCount` son bilinen degerde kalir
- sorun review totals hattindaysa:
  - trigger durdurulur
  - backfill script'i ile root rating alanlari yeniden normalize edilir

## F2-004 Uygulama Ciktilari

F2-004 tamamlandiginda sunlar beklenir:

- Functions:
  - favorite counter sync trigger
  - offer counter sync trigger
  - review metric sync trigger
  - `recordMarketViewBatch` callable
  - scheduled market view shard reducer
  - backfill script / admin runner
- Rules:
  - owner update denylist
- Test:
  - rules regression
  - functions unit/emulator testleri
  - market save/offer/review/view smoke

## Kabul Hukum

F2-003 kabul edildi:

- event kaynaklari netlestirildi
- alan bazli server ownership modeli secildi
- backfill, rollout ve rollback karari yazili hale getirildi
- `F2-004` icin uygulanabilir teknik hedef listesi cikarildi
