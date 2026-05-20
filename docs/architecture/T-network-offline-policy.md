# Network ve Offline Davranis Politikasi

Bu not, TurqApp icindeki ag, cache, medya, kuyruk ve upload davranislarinin tek karar modeliyle yonetilmesi icin kanonik teknik cercevedir.

## Durumlar

- `online`: Ag kullanilabilir kabul edilir. Canli okuma, medya fetch, background refresh ve kullanici aksiyon denemeleri serbesttir.
- `unstable`: Ham connectivity kisa sureli `none` sinyali vermistir, ancak offline dogrulanmamistir. Gorunur UI degistirilmez; liste, poster, avatar ve oynatma yuzeyleri korunur. Upload baslatilmaz.
- `offlineConfirmed`: `none` sinyali bekleme suresinden sonra tekrar dogrulanmistir. Yeni canli okuma ve medya fetch durur; yazma aksiyonlari offline kuyruguna alinabilir; upload baslatilmaz.

## Altin Kural

Offline sinyali gorunur icerigi yeniden kurmaz. Feed, story, short, chat, poster ve avatar yuzeyleri mevcut veriyi korur. Offline sadece yeni network islerinin nasil davranacagini belirler.

## Davranis Kurallari

- Feed/story/explore/profile: stale-while-revalidate. Mevcut liste korunur; canli refresh sadece `online` veya `unstable` iken denenir.
- Medya/poster/avatar: `unstable` durumda cache-only moda zorlanmaz. Fallback sadece gercek medya hatasi veya `offlineConfirmed` kosulunda devreye girebilir.
- Video playback: Aktif video connectivity dalgalanmasiyla durdurulmaz. Segment/playlist fetch karari merkezi policy uzerinden verilir.
- Like/save/comment/follow: `offlineConfirmed` ise offline queue kullanilir. `unstable` durumda aksiyon normal akista denenir.
- Upload/post olusturma: `unstable` veya `offlineConfirmed` durumda yeni upload baslatilmaz; kullaniciya mevcut no-internet/uyari akisi korunur.
- Chat/unread: `offlineConfirmed` olana kadar server sync araliklari offline moduna alinmaz.
- Prefetch: Sadece dogrulanmis offline durumda pause edilir; gecici sinyaller feed/short yuzeyini bozmaz.

## Tek Kaynak

Ham `connectivity_plus` sinyali yalnizca `NetworkAwarenessService` icinde okunur. Diger servisler `NetworkAwarenessService` tarafindan uretilen policy getterlarini kullanir.
