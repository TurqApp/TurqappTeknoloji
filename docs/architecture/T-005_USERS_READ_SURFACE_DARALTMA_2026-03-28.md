# T-005 `/users/{uid}` Okuma Yuzeyi Daraltma

## Kapsam

- Root `users` path icin genis `allow read: if isAuth();` kurali parcali hale getirildi.
- Yeni davranis:
  - `get`: tum authenticated kullanicilar icin acik kaldi
  - `list`: yalnizca authenticated + `limit <= 500` + `offset == 0` sorgularina acik

## Neden bu seviye secildi

Kod taramasinda root `users` query kullanan aktif akislar bulundu:

- `RecommendedUsersRepository.fetchCandidates(limit: 500)`
- `AdminPushRepository` sayfalama `pageSize = 350`
- `UserRepository` nickname/email/username queryleri `limit(1)`
- `searchUsersByNicknamePrefix(limit: 20)`

Bu nedenle owner-only veya cok dusuk limitli bir daraltma mevcut uygulama akislarini kirardi.
`500` ust limiti:

- sinirsiz root collection scan yuzeyini daraltir
- bilinen aktif sorgulari kirmaz
- daha derin public/private profile ayristirmasi icin gecis adimi olur

## Teknik kanit

- Rules degisikligi: `firestore.rules`
- Rules testleri:
  - authenticated limited list query izinli
  - authenticated direct get izinli
  - oversized list query `PERMISSION_DENIED`
- Komutlar:
  - `npm run build`
  - `npm run test:rules`

## Not

Bu is tam privacy modeli cozumu degil.
Bu, mevcut uygulama davranisini koruyarak root `users` listeleme yuzeyini sinirlayan minimum daraltmadir.
