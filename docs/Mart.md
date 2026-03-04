# Mart Oturum Ozeti

Bu dosya, Mart oturumunda proje uzerinde yapilan ana degisikliklerin kisa ozetidir.

## Altyapi ve Deploy

- `questionBankSkor` yapisi aylik modele tasindi: `questionBankSkor/{yyyy-MM}/items/{uid}`
- eski duz `questionBankSkor/{uid}` verileri aylik yapıya migration mantigiyla tasindi
- `resetMonthlyAntPoint` aylik puani `100` yapacak sekilde duzenlendi
- `Turkuaz` rozetliler puan tablosundan cikarildi
- `firestore.rules`, `storage.rules` ve ilgili function akislari bircok yerde guncellendi
- `qestionsBank` typo kalintilari aktif uygulama akisindan temizlendi

## Coz Gec ve Puan Tablosu

- puan tablosu `users` yerine `questionBankSkor` koleksiyonundan okunur hale getirildi
- sadece gercekten Coz Gec'te soru cozen kullanicilar leaderboard'a dusuyor
- aylik puan tablosu mantigi kuruldu
- baslik `Mart Ayi Puan Tablosu` olacak sekilde guncellendi
- `Siz` ayri satiri kaldirildi, siralama tek akis halinde gosterilecek sekilde duzenlendi
- `kullanici bulunamadi` fallback'i daha dogru bos durum metniyle degisti
- siralama mantigi ve turuncu/sari rozet filtreleri duzeltildi
- podyum birkac kez revize edildi; son durumda podyum korunuyor
- `questionBankSkor` icin gercek kullanicilar uid bazli baglandi

## Coz Gec Performans ve Cache

- ana kategori seciminde spinner/loading overlay eklendi
- secilen ana baslik icin lokal cache mantigi eklendi
- puan tablosunda gereksiz tekrar okumalar azaltildi
- liste gec acilma sorununu azaltmak icin gecici cache ve daha hafif render akisina gecildi

## Egitim Sekmeleri ve Adlandirma

- `Cikmis Sorular` sekmesi ve alt ekranlari `Denemeler` olarak yeniden adlandirildi
- yil bazli gridler `Deneme 1`, `Deneme 2` seklinde gosterilecek hale getirildi
- `Deneme Sinavlari` sekmesi `Online Sinav` olarak degistirildi
- egitim ekranindaki `Egitim Ekrani` metni `Egitim` yapildi

## Cevap Anahtari

- cevap anahtari duzenleme akisi calisir hale getirildi
- kapak yukleme akisi `webp` olarak korunarak duzeltildi
- storage yolu `books/{docID}/cover.webp` sekline alindi
- gridde yeni kapak gorselinin cache yuzunden gec yansimasi duzeltildi
- cevap anahtari istatistiginde yapay `x3` carpani kaldirildi, gercek goruntuleme sayisi gosteriliyor
- cevap anahtari kart menu akisinda `Goruntule`, `Sil`, `Duzenle`, `Vazgec` popup yapisi kuruldu

## Optik Form

- `OptikKodlar` koleksiyon adi `optikForm` olarak degistirildi
- kisitlamalar kaldirildi
- giris/onay ekranindaki metinler sade ve tehdit dili olmadan yeniden yazildi
- GetX kaynakli baslangic ekran patlamasi duzeltildi
- yayinladiklarim ekraninda optik formlarin gorunmesi icin refresh akisina mudahale edildi

## Is Bul ve Ozel Ders

- is ilanlarinda ve ozel derste paylasim `turqapp.com/i/...` kisa link mantigina baglandi
- is detayi paylasimi short link ureten servis uzerinden calisir hale getirildi
- is detayi kaydet akisi `users/{uid}/SavedIsBul/{docId}` uzerinden tek kaynakli hale getirildi
- ozel ders detayinda ve kart akisinda kaydet/paylas ikonlari yeniden duzenlendi
- `SavedTutoringsController not found` kirmizi ekran hatasi kapatildi
- is ve ozel ders basvurulari uygulama ici bildirimlere anlamli sekilde dusuruldu
- bu bildirimler feed'e sapmadan ilgili ilan detayina gidecek sekilde routing duzeltildi

## Push Bildirimleri

- postlarin uc nokta menusune admin icin `Push` secenegi eklendi
- admin hesaplari `osmannafiz` ve `turqapp` olarak ayarlandi
- push hedefleri gecici olarak belirli kullanicilarla sinirlandi
- iOS'ta cift bildirim sorununu azaltmak icin local notification davranisi duzeltildi
- iOS push gorseli icin `Notification Service Extension` eklendi ve attachment akisina mudahale edildi
- Android push ikonu icin ayri `ic_notification_small` resource'u tanimlandi
- bildirimden acilan post/ilan/ozel ders ekranlari icin route akislarina ince ayar yapildi

## Feed

- video autoplay mantigi birkac kez revize edildi; eski daha deterministik modele yaklastirildi
- video erken stop etme problemi uzerinde esik ve gorunurluk temelli duzeltmeler yapildi
- `Kes` yazisi kaldirildi, cache videosu gostergesi yesil nokta olarak birakildi
- nickname, zaman, caption ve header spacing'i birkac kez duzenlendi
- zaman formatlari `1dk`, `1sa`, `1g`, `1ay`, eski tarihlerde `22 Ara 25` formatina cekildi
- caption fazla uzunsa `devami` ile acilan yapi kuruldu
- action butonlari, ikon boyutlari, rakam boyutlari ve spacing birkac kez yeniden ayarlandi
- aktif renkler:
  - begeni: mavi
  - kaydet: sari
  - yeniden paylas: yesil

## Kesfet

- `Sana Ozel` video gridinde oransal filtreler denendi
- yeniden paylasilan tekrar videolari eleme ve `aspectRatio` filtreleri uzerinde duzeltmeler yapildi
- daha sonra fazla bozulan onerilen videolar denemesi geri alindi
- son durumda `Onerilen Videolar` blogu iptal edildi, `Onerilen Kisiler` yapisi korundu

## Onerilen Kisiler

- blok boyutu ve kart sayisi kucultuldu
- baslik `Onerilen Kisiler` yapildi
- gosterim frekansi feed icinde ayarlandi
- cizgi ve ust bosluklara yakinlastirma yapildi

## Slider Yonetimi

- admin hesaplar icin `Denemeler`, `Online Sinav`, `Cevap Anahtari`, `Ozel Ders`, `Is Bul` modullerine slider yonetimi eklendi
- slider gorselleri `slider/{modul}/{id}.webp` yoluna `webp` olarak yazilacak sekilde tasarlandi
- Firebase kurallari yazma/isleme akisina gore guncellendi

## CV ve Profil

- LinkedIn alani zorunlu olmaktan cikarildi
- bildirim ayarlari icin ayarlar altina yeni bir `Bildirimler` ekrani eklendi
- kullanici bazli bildirim tercihleri `users/{uid}/settings/notifications` altinda tutulacak sekilde servis yazildi

## Diger Notlar

- bircok Android ve iOS `run`, `release`, `hot reload` ve `deploy` denemesi yapildi
- iOS release build tarafinda extension ve bundle version kaynakli build/launch sorunlari duzeltildi
- bazi yerlerde Firestore `PERMISSION_DENIED`, `AdWidget requires Ad.load`, eksik slider asset ve benzeri yan sorunlar not edildi

## Git

- oturum boyunca birden fazla checkpoint commit'i alindi
- kullanici istegiyle tam commit ve push akislari da yapildi
