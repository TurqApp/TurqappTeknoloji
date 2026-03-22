# Typesense Posts Remaining Tasks

## Durum
- `feed`, `short`, `fullscreen`, `photo-short` tarafında `authorNickname`, `authorDisplayName`, `authorAvatarUrl`, `rozet` post kartından okunacak şekilde kod güncellendi.
- `posts_search` için tekrarlı alanlar kod tarafında büyük ölçüde temizlendi.
- `originalPostID` ve `originalUserID` bilerek bırakıldı.
  Reshare/quote ve bazı agenda/explore akışları bunlara bağlı.

## Açık Kalan Operasyonel İşler
1. `posts_search` koleksiyonunu bir kez daha tamamen sil.
   Amaç: eski legacy field'ların Typesense koleksiyonunda fiziksel olarak kalmamasını sağlamak.
2. Silme sonrası yeni bir post oluştur veya `reindex` çalıştır.
   Amaç: koleksiyonun yeni minimal şemayla yeniden oluşmasını sağlamak.
3. Yeni oluşan `posts_search` dokümanını kontrol et.
   Beklenen post alanları:
   - `id`
   - `userID`
   - `authorNickname`
   - `authorDisplayName`
   - `authorAvatarUrl`
   - `rozet`
   - `metin`
   - `img`
   - `thumbnail`
   - `video`
   - `hlsMasterUrl`
   - `hlsStatus`
   - `hasPlayableVideo`
   - `aspectRatio`
   - `paylasGizliligi`
   - `arsiv`
   - `deletedPost`
   - `gizlendi`
   - `isUploading`
   - `likeCount`
   - `commentCount`
   - `savedCount`
   - `retryCount`
   - `statsCount`
   - `flood`
   - `floodCount`
   - `mainFlood`
   - `originalPostID`
   - `originalUserID`
   - `quotedPost`
   - `locationCity`
   - `contentType`
   - `editTime`
   - `timeStamp`
   - `createdAtTs`
   - `hashtags`
   - `mentions`

## Özellikle Olmaması Gerekenler
- `caption`
- `captionPreview`
- `nickname`
- `username`
- `fullName`
- `avatarUrl`
- `authorId`
- `playbackUrl`
- `hlsUrl`
- `hlsThumbnailUrl`
- `rawVideoUrl`
- `imageURL`
- `previewUrl`
- `viewCount`
- `hlsUpdatedAt`

## Son Test Checklist
1. Yeni post oluştur.
2. Feed kartında `@nickname` posttan gelsin.
3. Büyük isim `authorDisplayName` olsun.
4. Rozet doğrudan karttan görünsün.
5. Aynı post short/fullscreen/keşfet açılışında da aynı değerlerle gelsin.
6. Video post HLS hazır değilse Typesense'e düşmesin.
7. HLS hazır olunca Typesense'e düşsün.

## Not
- Kod tarafında `dart analyze lib` temiz geçti.
- Functions tarafında `npm run build` temiz geçti.
- Typesense tarafında tam temiz sonuç için koleksiyonun yeniden silinip oluşturulması şart.
