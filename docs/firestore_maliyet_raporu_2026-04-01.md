# Firestore Maliyet Düşürme Raporu

## 1. Amaç

Bugünkü çalışmanın ana hedefi, uygulamanın davranışını bozmadan Firestore üzerindeki gereksiz `read`, `listener`, `write` ve bunlara bağlı Functions/Typesense zincir maliyetlerini düşürmekti. Odak özellikle şu alanlardaydı:

- gereksiz canlı dinleyicileri daraltmak
- tam koleksiyon taramalarını noktasal okumalara çevirmek
- kapalı sekmelerin arka planda veri çekmesini engellemek
- startup anındaki gereksiz ağ yükünü azaltmak
- per-user cache ve local patch ile full refresh zincirlerini kırmak
- Function tarafında sürekli çalışan veya gereksiz tekrar üreten işleri kısmak

## 2. Bugün Tamamlanan Başlıca İyileştirmeler

### A. Chat tarafı

Commitler: `c4616840`, `95eacaa6`, `fe58c48b`

Yapılanlar:

- sohbet canlı senkronu tüm geçmiş yerine yalnız aktif/pencere üstü alanla sınırlandı
- unread senkronu cache-first hale getirildi
- forward picker ve chat liste akışı cache-first/local-first hale getirildi

Net etki:

- eski konuşmalar için gereksiz Firestore listener sayısı düştü
- chat liste açılışında tekrar tekrar geniş okuma azaldı
- mesajlaşma hissi korunurken read maliyeti aşağı çekildi

### B. Post interaction okumaları

Commit: `ccb734b6`

Yapılanlar:

- like/save/reshare/comment status kontrolünde tam subcollection taraması kaldırıldı
- yerine daha dar ve noktasal okuma modeli kullanıldı

Net etki:

- interaction state kontrolü için yapılan Firestore read sayısı ciddi biçimde düştü
- özellikle feed ve detay kartlarında pahalı kontrol kalıpları kırıldı

### C. Pasaj / Market / İş / Burs / Özel Ders

Commitler: `0715d320`, `f2658666`, `0da633d5`, `b178237b`, `5a0eaf9d`, `56029dc8`, `ba710ca8`, `9e2661f2`, `fae13dfe`, `9bd92ca4`, `2efaaaa2`

Yapılanlar:

- market sıcak yüzeylerde medya cache-first hale getirildi
- market doküman hydrate akışı Typesense üzerinden batch hale getirildi
- market, education ve posts Typesense sync tarafında no-op durumlar atlanmaya başladı
- market dışındaki Pasaj sıcak yüzeyleri de cache-first hatta alındı
- market owner/my-items bootstrap kısmı Typesense cache'den ısınabilir hale getirildi
- splash warmup'ta Pasaj sekmeleri route-hint/gate ile daraltıldı
- ayarlardan kapalı olan Pasaj sekmelerinde Firestore ve Typesense akışı tamamen durduruldu
- market create/edit önizleme görselleri de cache-first oldu

Net etki:

- Pasaj sekmelerinde gereksiz liste/read çağrıları azaldı
- kapalı sekmeler artık yalnız gizlenmiyor, ağ yükü de kesiliyor
- Functions tarafında gereksiz Typesense upsert zinciri de daraldı
- Firestore + Functions + Typesense birleşik maliyeti aşağı çekildi

### D. Eğitim tarafı answered/history akışları

Commitler: `e89fdff4`, `fcc97b0f`, `ca9157e4`

Yapılanlar:

- practice exam answered akışı için per-user answered ref cache getirildi
- optical form answered akışı için benzer per-user ref modeli eklendi
- legacy `Tests` modülü aktif olmadığı için ağ trafiği no-op hale getirildi

Net etki:

- `collectionGroup('Yanitlar')` gibi pahalı geçmiş taramaları tekrar tekrar çalışmaz hale geldi
- eski kullanıcılar için fallback/backfill korunurken sürekli global tarama kesildi
- aktif olmayan Tests modülü artık gereksiz Firestore trafiği üretmiyor

### E. Profile / Current User refresh zinciri

Commitler: `b140d24e`, `a8258974`, `374e1345`, `dc418025`, `a9c18c59`, `5f49bf26`

Yapılanlar:

- `lastSearches` ve `blockedUsers` gibi alanlarda full `forceRefresh()` yerine local patch kullanıldı
- profil düzenleme akışlarında gereksiz current user full refresh kaldırıldı
- profile geri dönüşlerinde tam refresh yerine hedefli refresh kullanıldı
- auth sonrası redundant `forceRefresh()` çağrıları azaltıldı
- profile cache bütçeleri netleştirildi:
  - ana post sekmesi `20`
  - diğer sekmeler `10`
  - startup shard `10`
- reshare cache/snapshot davranışı daha kalıcı hale getirildi

Net etki:

- root `users/{uid}` okuma zinciri belirgin biçimde azaldı
- profil dönüşleri ve düzenleme akışları daha hafifledi
- aynı davranış korunurken gereksiz read maliyeti düştü

### F. Startup / Warmup davranışı

Commitler: `adfdf20a`, `9afd093b`

Yapılanlar:

- feed startup modeli `20 + 10 + 3` olarak kademelendi
- short startup `30` olarak ayarlandı
- story `10 + 5 + 5` kademeli yükleme modeline çekildi
- Pasaj sekmeleri için minimum cache ve tab açılınca genişleme modeli uygulandı
- video segment prefetch zinciri sıralı hale getirildi; segment atlaması kapatıldı

Net etki:

- uygulama ilk açılışta boş görünmeden daha kontrollü veri çekiyor
- gereksiz erken fetch azaltıldı
- hem Firestore hem medya tarafında startup patlaması kontrol altına alındı

### G. Hashtag keşfi

Commit: `6e5e23c3`

Yapılanlar:

- hashtag'a tıklanınca gelen post listesi Typesense-first hale getirildi
- Firestore fallback korunarak risk azaltıldı

Net etki:

- hashtag keşfi için Firestore tarafındaki pahalı post arama/read yükü azaldı
- keşif akışı search motoruna taşınarak daha ucuz hale geldi

## 3. Function Tarafında Yapılan Optimizasyonlar

### A. Reklam günlük aggregation

Commit: `b55c92d4`

Yapılanlar:

- hourly ads aggregation tüm günü ve tüm kampanyaları kör taramak yerine daraltıldı
- sadece aktif/onaylı campaign'ler hedeflendi
- flags kapalıysa erken çıkış eklendi
- delivery log tarafında dedupe uygulandı

Net etki:

- gereksiz Firestore read ve Functions işi azaldı
- özellikle reklam tarafı sıcak değilse baseline maliyet düştü

### B. Users Typesense reindex

Commit: `08c32ec6`

Yapılanlar:

- `users_search` payload sadeleştirildi
- arama `nickname + displayName` olarak tutuldu
- scheduled reindex `5 dk` yerine `60 dk` oldu
- ayrıca yalnız `adminConfig/typesenseUsersReindex.enabled == true` ise çalışacak hale getirildi
- iş bitince kendini kapatır hale geldi

Net etki:

- sürekli user tarayan scheduler davranışı kırıldı
- user değişince güncellik yine trigger ile korunuyor
- backfill/reindex işi sadece ihtiyaç halinde çalışıyor

### C. Story archive duplicate write

Commit: `4ab483a8`

Yapılanlar:

- süresi biten hikaye ve manuel silinen hikaye akışları korunurken duplicate archive write kaldırıldı

Net etki:

- aynı story için iki kez archive yazılması engellendi
- özellik korunurken Firestore write maliyeti düştü

### D. Notification push zinciri

Commit: `4f55e2e0`

Yapılanlar:

- `onUserNotificationCreate` içinde gereksiz sıralı okumalar daraltıldı
- config/prefs okuma sırası optimize edildi
- medya destekli push davranışı aynen korundu

Net etki:

- push davranışı değişmeden Firestore read ve function latency maliyeti düştü

## 4. Geri Alınan Denemeler

Aşağıdaki denemeler yapıldı ancak kullanıcı kararıyla geri alındı; bu yüzden final durumda geçerli değiller:

- `authorNickname / authorDisplayName / authorAvatarUrl / rozet` alanlarını post write anında inline yazma
- `09_userProfile.ts` otomatik profile-update sync'ini kapatma
- Typesense content koleksiyonlarına ortak author alias ekleme

Bu nedenle final durumda:

- [09_userProfile.ts](/Users/turqapp/Desktop/TurqApp/functions/src/09_userProfile.ts)
- [authorDenorm.ts](/Users/turqapp/Desktop/TurqApp/functions/src/authorDenorm.ts)

ikisi de aktif ve mevcut davranış korunmuş durumda.

## 5. Deploy Durumu

Canlıya çıkarılan function değişiklikleri:

- user search / reindex gate tarafı
- story archive duplicate fix
- notification push read optimizasyonu

Henüz app build/release gerektiren ama function deploy gerektirmeyen/app tarafında kalan işler:

- profile cache ve refresh iyileştirmeleri
- Pasaj/market/job/burs/özel ders cache-first iyileştirmeleri
- startup/warmup bütçeleri
- hashtag Typesense-first akışı
- market detail save/favorite parity düzeltmesi

## 6. Beklenen Toplam Etki

En yüksek kazanç beklenen alanlar:

- chat read ve listener maliyeti
- interaction status read maliyeti
- answered/history collectionGroup maliyeti
- profile/current user gereksiz full refresh maliyeti
- kapalı Pasaj sekmelerinin arka plan yükü
- user reindex scheduler baseline maliyeti
- duplicate story archive write maliyeti

Orta-yüksek ek kazanç:

- startup sonrası ilk dakika ağ yükü
- hashtag keşfinde Firestore read azalması
- Typesense no-op sync azaltmaları
- Functions tarafında reklam/notification read daralmaları

## 7. Sonuç

Bugünkü çalışma sonunda Firestore maliyetini artıran ana kalıplar büyük ölçüde daraltıldı: gereksiz listener, full subcollection read, collectionGroup tabanlı geniş tarama, full current-user refresh, kapalı sekmelerin arka plan ağı ve sürekli çalışan reindex/duplicate function davranışları önemli ölçüde azaltıldı.

Kısa özetle:

- yüksek etkili sıcak ceplerin büyük bölümü kapatıldı
- ürün davranışı ağırlıklı olarak korundu
- kalan işler artık daha çok ince ayar ve karar bazlı optimizasyon seviyesinde
