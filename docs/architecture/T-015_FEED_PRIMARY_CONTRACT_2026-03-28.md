# T-015 Feed Primary Contract

## Amac

Home feed icin tek birincil istemci yolunu isimli ve testlenebilir hale
getirmek.

## Kanonik Istemci Sozlesmesi

- Contract ID: `feed_home_primary_hybrid_v1`
- Birincil kaynak:
  - `userFeeds/{uid}/items` referanslari
  - istemci tarafinda [fetchHomePage](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart)
    icindeki `fetchUserFeedReferences` cagrisi ile baslar
- Ek zenginlestirme kaynaklari:
  - kullanicinin kendi guncel postlari
  - celebrity/fan-in yazar postlari
  - gorunur public scheduled `iz birak` postlari
  - global badge postlari
- Fallback sirasi:
  1. personal snapshot fallback
  2. legacy page fallback

## T-015 Kapsami

- Davranisi yeniden yazmak degil
- Birincil istemci yolunu isimli contract'a baglamak
- Sonraki `T-016` isine istemci/backend hizalama zemini hazirlamak

## Kabul Kriteri Kaniti

- `FeedHomeContract.primaryHybridV1` eklendi
- `FeedSnapshotRepository` bu contract'a baglandi
- Hedefli contract testi eklendi
