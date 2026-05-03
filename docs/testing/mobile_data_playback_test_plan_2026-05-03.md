# Mobil Veri Playback Test Plani

Tarih: 2026-05-03  
Kapsam: Feed, Short, Profile surfaces  
Amac: Mobil veri davranisinda gereksiz veri tuketimi, hedef-disi preload, quota fill regressions ve autoplay playback regressions tespit etmek.

## 1. Hedefler

- Mobil veride quota fill'in tamamen kapali oldugunu dogrulamak
- Aktif video disinda sadece beklenen komsu hazirliklarin calistigini dogrulamak
- Hedef disina cikan videolarin yeni veri tuketmedigini dogrulamak
- Feed, Short ve Profile surfaces arasinda davranis farklarini olcmek
- Mobil veri davranisinin playback kalitesini bozup bozmadigini gozlemek

## 2. Beklenen Davranis

- Aktif video playback veri tuketir
- `+1` ve `+2` komsu sinirli hazirlik alabilir
- `+3` ve sonrasi yeni veri tuketmemeli
- Hedeften cikan `-1 / -2` videolar cache'de kalabilir ama yeni veri cekmemeli
- Mobil veride quota fill hic devreye girmemeli

## 3. Ana Log/Sinyal Anahtarlari

- `HlsOffscreenLeak`
- `ShortQuotaFill`
- `FeedPlayWindow`
- `PlaybackStopTrace`
- `FeedNetworkPolicy`
- `ShortNetworkPolicy`
- `cellularDownloadedBytes`
- `cellularBackgroundDownloadedBytes`
- `cellularPrefetchDownloadedBytes`
- `cellularPlaybackDownloadedBytes`
- `cellularBackgroundRatio`

## 4. Test Ortami

### Android

```bash
flutter run -d R5CN80MZ17A --dart-define=QA_LAB_ENABLED=true
```

### iOS

```bash
flutter run --release -d 00008140-000C0D903488801C --dart-define=QA_LAB_ENABLED=true
```

Not:

- QA Lab acik olmali
- Testler ayni build ile yapilmali
- Mumkunse temiz app acilisi tercih edilmeli
- Ayni hesapla tum yuzeyler test edilmeli

## 5. Test Matrisi

### T1 Feed soguk acilis

- Uygulamayi ac
- Feed ilk videoda 15 saniye bekle

Beklenen:

- Ilk video autoplay alir
- `ShortQuotaFill` quota plan baslatmaz
- Background veri tuketimi dusuk kalir

Kayit:

- First frame suresi
- `cellularPlaybackDownloadedBytes`
- `cellularBackgroundDownloadedBytes`

### T2 Feed yavas swipe

- 5 video asagi kaydir
- Her videoda 3-4 saniye bekle

Beklenen:

- Aktif video oynar
- Komsu hazirligi var ama uzak offset tuketimi yok
- Playback handoff temiz

Kayit:

- `FeedPlayWindow`
- `PlaybackStopTrace`
- varsa `HlsOffscreenLeak`

### T3 Feed hizli swipe

- Arka arkaya 10-15 hizli swipe yap

Beklenen:

- Eski hedef yeni veri tuketmemeli
- Hedef-disi quota transfer olmamali

Kayit:

- `HlsOffscreenLeak signal=quota_background_transfer`
- `cellularPrefetchDownloadedBytes`
- `cellularBackgroundRatio`

### T4 Feed geri swipe

- 3 video asagi in
- Sonra geri yukari don

Beklenen:

- Cache'den toparlama olabilir
- Geri tarafta yeni veri cekimi artmamali

Kayit:

- `PlaybackStopTrace`
- `HlsOffscreenLeak`
- gozlemsel acilis hizi

### T5 Feed uzun bekleme

- Tek videoda 60 saniye kal

Beklenen:

- Aktif playback disinda agresif yeni prefetch olmamali

Kayit:

- `cellularPlaybackDownloadedBytes`
- `cellularBackgroundDownloadedBytes`

### T6 Short soguk acilis

- Short ac
- Ilk videoda 20 saniye bekle

Beklenen:

- Autoplay temiz
- Quota fill yok

Kayit:

- `ShortNetworkPolicy`
- `ShortQuotaFill`

### T7 Short hizli gecis

- 15 hizli swipe yap

Beklenen:

- Aktif disi veri tuketimi dusuk
- Ready/play handoff temiz

Kayit:

- `PlaybackStopTrace`
- `HlsOffscreenLeak`
- `cellularPrefetchDownloadedBytes`

### T8 Profile video swipe

- Kendi profil ve karsi profil ac
- 5'er video swipe yap

Beklenen:

- Feed'e yakin playback davranisi
- Gec baslama ve parlama minimum
- Hedef-disi veri tuketimi olmamali

Kayit:

- `FeedPlayWindow`
- `PlaybackStopTrace`
- gozlemsel poster/parlama notu

### T9 Tab degisimi

- Feed -> baska tab -> geri
- Short -> baska tab -> geri

Beklenen:

- Eski gorunmeyen surface veri cekmemeli
- Donus sonrasi autoplay kilitlenmemeli

Kayit:

- `FeedNetworkPolicy`
- `ShortNetworkPolicy`
- `HlsOffscreenLeak`

### T10 Uzun oturum

- 10 dakika karisik kullanim:
  - Feed
  - Short
  - Profile

Beklenen:

- Toplam veri tuketimi playback agirlikli olmali
- Background oran dusuk olmali

Kayit:

- QA Lab summary
- runtime export
- tum cellular usage alanlari

## 6. Basari Kriterleri

- Mobil veride quota fill: `0`
- `cellularBackgroundRatio` dusuk kalmali
- Aktif playback bytes, background bytes'tan belirgin yuksek olmali
- `+3` ve sonrasi icin anlamli prefetch olmamali
- Hedef disi videolarda yeni veri cekimi gorunmemeli

## 7. Kirmizi Bayraklar

- `ShortQuotaFill status=plan_start` mobil veride gorunuyorsa
- `HlsOffscreenLeak signal=quota_background_transfer`
- Gorunmeyen doc icin tekrarli segment hareketi
- Hizli swipe sonrasi eski hedefte yeni download

## 8. Test Kayit Formu

Her senaryo icin su formatla not dus:

- Surface:
- Senaryo:
- Cihaz:
- Build:
- Baslangic saati:
- Sure:
- Gozlemsel sonuc:
- Log ozeti:
- Playback bytes:
- Prefetch bytes:
- Background bytes:
- Hukum: Temiz / Supheli / Bug

## 9. Ilk Tur Onerisi

Ilk QA turunda sira:

1. T1 Feed soguk acilis
2. T3 Feed hizli swipe
3. T6 Short soguk acilis
4. T7 Short hizli gecis
5. T8 Profile video swipe
6. T10 Uzun oturum

## 10. Bu Turun Ozel Kontrolu

Bu turda ozellikle su dogrulanacak:

- Mobil veride quota fill gate kapali mi
- Feed disi yuzeylerde yeni veri tuketimi gorunuyor mu
- `+1 / +2` disinda yeni segment hazirligi oluyor mu
- Hedeften cikan videolar yeni veri yemeye devam ediyor mu
