# T-006 `marketStore` Client Counter Update Yolunu Kapatma

## Kapsam

- `marketStore/{itemId}` root dokumani icin client tarafindan counter update izni kaldirildi.
- Artik `marketStore` root item update yalnizca item owner tarafindan yapilabilir.
- Viewer/favorite/offer/review kaynakli root counter yazimlari client kodundan cikarildi.

## Kapatilan client yazim noktalari

- `MarketRepository.incrementViewCount`
- `MarketSavedStore.save / unsave`
- `MarketOfferService._createOfferImpl`
- `MarketReviewService.submitReview / deleteReview`

## Neden

Bu yol daha once client'tan su alanlarin dogrudan yazilmasina izin veriyordu:

- `viewCount`
- `favoriteCount`
- `offerCount`
- `averageRating`
- `reviewCount`
- `lastOfferAt`

Bu, item owner olmayan authenticated istemcilerin root item sayaçlarini etkileyebilmesi anlamina geliyordu.

## Teknik kanit

- Rules degisikligi: `firestore.rules`
- Rules testleri:
  - viewer counter increment artik reddediliyor
  - owner item update hala izinli
- Komutlar:
  - `npm run test:rules`
  - `dart analyze --no-fatal-warnings --no-fatal-infos ...market dosyalari`

## Acik kalan risk

Bu is security yolunu kapatir; fakat market sayaclari icin server-side aggregation henuz yok.
Bu nedenle:

- local UI optimistic olarak artis gosterebilir
- server root item sayaçlari stale kalabilir

Bu risk ayri kayit olarak izlenmelidir.
