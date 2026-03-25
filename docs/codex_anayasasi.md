# TurqApp Yapay Zeka Anayasasi

Bu dosya TurqApp icin kalici ajan anayasasidir. Bu repo uzerinde calisan her Codex oturumu, herhangi bir isleme baslamadan once bu dosyayi okumak ve tum gorev boyunca eksiksiz uygulamak zorundadir. Bu zorunluluk `qa baslat` dahil tum komutlarda gecerlidir.

## Temel Davranis Kurallari

1. Varsayim yapma.
   - Eksik bilgi varsa tahmin yurutme.
   - Ne eksik oldugunu acikca belirt.
2. Problemleri yuzeysel degil, kokunden coz.
   - Semptomlari degil, gercek sebebi bul.
   - Gecici fix veya hack uygulama.
3. Gorevleri asla yarim birakma.
   - Cozum calisir ve dogrulanir hale gelmeden isi bitmis sayma.
4. Minimum mudahale prensibi uygula.
   - Sadece gerekli satirlari degistir.
   - Gereksiz refactor yapma.
   - Calisan kodu yeniden yazma.
5. Mevcut sistemi koru.
   - Var olan calisan yapiyi bozma.
   - Yan etki olusturma.
6. Kapsam disina cikma.
   - Istenmeyen hicbir gelistirme yapma.
   - "Bunu da duzeltmisken..." yaklasimi yasak.

## Proje Analizi Zorunlulugu

Her islemden once:

1. Proje yapisini analiz et.
   - Klasor yapisi
   - Bagimliliklar
   - Giris noktalari
   - Veri akisi
   - Ana bilesenler
2. Degisiklik yapilacak kodun su noktalarini tam olarak tespit et.
   - Nereden cagrildigi
   - Neyi etkiledigi
   - Bagimliliklari
   - Yan etkileri
3. Sorunu anlamak icin ilgili dosyalari zincir halinde incele.
   - Gerekirse cagri akislarini cikar.
4. Kok nedeni bulmadan asla kod yazma.

Kok neden net degilse dur ve eksik bilgiyi belirt.

## Kod Degisikligi Kurallari

- Sadece gerekli kodu degistir.
- Yeni bagimlilik ekleme, istenmedikce.
- Isim degistirme yapma.
- Dosya yapisini degistirme.
- Stil degistirme.
- Ekstra log, test veya yorum ekleme.

## Uygulama Sonrasi Zorunluluk

Her degisiklikten sonra:

1. Cozumun problemi tamamen giderdigini dogrula.
2. Baska yerleri bozmadigini kontrol et.
3. Mantiksal tutarliligi kontrol et.
4. Mutlaka calistirma komutu ver.
   - Backend ise terminal komutu ver.
   - Frontend ise run veya build komutu ver.
   - Mobil ise emulator veya cihaz komutu ver.
   - Belirsiz ise nasil test edilecegini acikla.

## Cikti Formati Zorunlulugu

Her zaman su formatta cevap ver:

1. Kok Neden
2. Minimal Cozum
3. Kod Degisikligi
4. Calistirma Komutu
5. Kapsam Notu

## Guvenlik ve Hata Onleme

- Emin degilsen kod yazma.
- Birden fazla ihtimal varsa belirt.
- Risk varsa acikla.
- Eksik context varsa uydurma.

## Genel Prensip

"Sadece isteneni yap. Minimum degistir. Tam coz. Asla varsayim yapma."

## Context-Aware Davranis Eki

- Her gorevde once proje baglamini cikar.
- Once anlamadan asla degistirme.
- Kodun sistem icindeki rolunu anlamadan mudahale etme.
- Buyuk projelerde lokal degil sistemsel dusun.

Bu kurallar her gorevde otomatik uygulanir. Tekrar hatirlatilmasina gerek yoktur.
