# HLS + AVPlayer İş Planı

Bu doküman, projede sadece HLS segment altyapısı ve AVPlayer entegrasyonu için izlenecek adımları içerir.

## Kilit Kurallar

- Firestore koleksiyon yapısı değişmeyecek.
- Yeni koleksiyon adı üretilmeyecek.
- Şema alanı ekleme/silme yapılmayacak.
- Her adım kullanıcı onayı ile ilerletilecek.
- HLS dışında iş kapsamı genişletilmeyecek.

## Mevcut Durum Özeti

- iOS tarafında native AVPlayer köprüsü eklendi.
- Flutter tarafında AVPlayer platform view köprüsü eklendi.
- Story video akışında iOS için AVPlayer kullanımı başlatıldı.
- HLS transcode/segment üretim hattı henüz yok.
- `PostsModel` içinde HLS alanı eklenmiş durumda (kural gereği geri alınacak).

## Faz 0 - Kural Uyum ve Temizlik

Hedef: "koleksiyon/şema değişmez" kuralını geri sağlamak.

1. `PostsModel` içindeki HLS alanlarını geri al.
2. Kod genelinde `Posts.video` harici yeni alan kullanımını temizle.
3. İş kuralını teknik not olarak dokümana sabitle.

Çıktı:
- Şema dokunulmamış temiz kod tabanı.

## Faz 1 - AVPlayer Köprü Stabilizasyonu

Hedef: iOS native oynatıcıyı üretim stabilitesine getirmek.

1. Swift köprüde event setini tamamla:
   - `ready`
   - `ended`
   - `error`
   - opsiyonel `progress` (position/duration)
2. Method kanal komutları netleştir:
   - `play`, `pause`, `seekTo`, `setMuted`, `setLooping`, `setFit`, `setSource`, `dispose`
3. Flutter köprü katmanında lifecycle sağlamlaştır:
   - route push/pop
   - widget update
   - pause/resume
   - mute senkronu

Çıktı:
- Story akışında stabil AVPlayer.

## Faz 2 - HLS Segment Üretim Altyapısı

Hedef: MP4 kaynaktan HLS (`master.m3u8` + segmentler) üretmek.

1. Storage trigger ile video yükleme olayını yakala.
2. Backend transcode işi çalıştır:
   - öneri: Cloud Transcoder API veya Cloud Run + FFmpeg
3. Çıktıları storage altında düzenli path'e yaz.
4. Transcode tamamlanınca sadece mevcut `Posts.video` alanını `master.m3u8` URL ile güncelle.
5. Hata durumunda `Posts.video` mp4 olarak kalır (fallback).

Çıktı:
- Şema değiştirmeden HLS publish.

## Faz 3 - Upload Akışlarını HLS ile Uyumlama

Hedef: Video yükleyen tüm yolların HLS pipeline ile çalışması.

Kapsam:
1. `PostCreator`
2. `UploadQueueService`
3. `EditPost`
4. `ShareOfPost`
5. `UrlPostMaker`

Her akış için kural:
- İlk upload: mp4
- Backend transcode: hls
- Final playback URL: `Posts.video`

## Faz 4 - Oynatma Katmanına Yayılım

Hedef: iOS'ta AVPlayer, diğer platformlarda mevcut player ile devam.

1. Story (tamamlanmış)
2. Feed / Agenda video oynatma
3. Tag mini player
4. Shorts ve SingleShort akışları

Not:
- Android tarafı mevcut `video_player` ile devam eder.
- iOS tarafında AVPlayer öncelikli.

## Faz 5 - HLS Özel Teknik Düzeltmeler

Hedef: HLS/MP4 karma kullanımında performans ve kararlılık.

1. Shorts disk cache mantığını `.m3u8` için uyumlu hale getir.
2. Preload/seek/pause davranışlarını HLS için doğrula.
3. Feed içinde karışık formatta stabil playback sağla.

## Faz 6 - Test ve Yayın Planı

1. Fonksiyonel test:
   - Yeni video post
   - Edit video
   - Share video
   - Story video
2. Ağ testleri:
   - Düşük bant
   - Kesinti ve geri dönüş
3. Fallback test:
   - Transcode fail -> mp4 oynatma
4. Kademeli yayın:
   - Internal test
   - TestFlight
   - Production

## Onay Kapıları

1. Onay A: Faz 0
2. Onay B: Faz 1
3. Onay C: Faz 2
4. Onay D: Faz 3 + Faz 4
5. Onay E: Faz 5 + Faz 6

---

Bu plan, kullanıcı talebine göre sadece HLS + AVPlayer kapsamı için hazırlanmıştır.
