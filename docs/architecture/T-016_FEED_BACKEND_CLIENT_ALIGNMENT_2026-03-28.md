# T-016 Feed Backend / Client Contract Alignment

## Amac

`hybridFeed.ts` tarafindaki referans semasini, istemcide tanimlanan
`feed_home_primary_hybrid_v1` contract'i ile ayni isimli ve ayni alanli hale
getirmek.

## Hizalanan Noktalar

- `contractId`: `feed_home_primary_hybrid_v1`
- primary collection: `userFeeds`
- item subcollection: `items`
- celebrity collection: `celebAccounts`
- zorunlu reference alanlari:
  - `postId`
  - `authorId`
  - `timeStamp`
  - `isCelebrity`
  - `expiresAt`

## T-016 Kapsami

- backend contract constant dosyasi eklendi
- hybrid feed yazma noktalarinda bu constant kullanildi
- client contract ayni storage semasi ile genisletildi
- hem Dart hem Functions tarafinda hedefli test eklendi

## Kapsam Disi

- feed ranking veya fallback davranisinin yeniden yazilmasi
- `AgendaController` orchestration cikarimi
- social feed read-path refactor'i
