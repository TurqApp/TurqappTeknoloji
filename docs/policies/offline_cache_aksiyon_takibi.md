# Offline Cache Aksiyon Takibi

Bu dosya, offline/media cache davranisi icin alinmis urun kararlarini ve
uygulama durumunu anayasa metninden ayri takip etmek icin tutulur.

## Takip Kurali

- Anayasa degismez mimari ve ownership kurallarini tasir.
- Bu dosya ise offline cache aksiyonlarini, durumlarini ve siradaki
  uygulama adimlarini tasir.
- Her aksiyon icin tek durum kullanilir:
  - `beklemede`
  - `devam ediyor`
  - `tamamlandi`
  - `sonraya alindi`

## Mevcut Kararlar

### 1. Sadece Rozetli Hesaplar

- Durum: `tamamlandi`
- Karar:
  - otomatik offline/cache adayi yalniz rozetli hesap videolari olacak
- Not:
  - ileride `yuksek begeni` sinifi eklenebilir
  - bugunku ilk filtre yalniz `rozetli`

### 2. Tam Video Indirme

- Durum: `tamamlandi`
- Karar:
  - cache'e alinan video segment bazli yari indirme degil, tam video olarak
    inecek
- Uygulama:
  - Wi-Fi tarafinda kuyruklu worker tam video mantigina baglandi
- Commit:
  - `63252782`

### 3. Wi-Fi Doluluk Hedefi

- Durum: `tamamlandi`
- Karar:
  - Wi-Fi varsa efektif cache kotasinin yaklasik `%70`ine kadar doldur
- Not:
  - standart plan `3+1 GB` olarak dusunulur
  - runtime hedef stream cache hard-stop'un `%70`idir

### 4. Izlenen Video Silme Penceresi

- Durum: `tamamlandi`
- Karar:
  - izlenen video `6 saat` sonra silme icin birinci aday olur
- Not:
  - aninda silinmez
  - kisa sure sonra tekrar acilmak istenirse cache'de kalir

### 5. Kalici Kutuphane Olmayacak

- Durum: `tamamlandi`
- Karar:
  - sistem kalici offline kutuphane gibi davranmayacak
  - cache yeni videolarla donmeye devam edecek
  - kullaniciya "saklanan" ayri kalici medya sinifi acilmayacak

### 6. Silme Sirasi

- Durum: `tamamlandi`
- Karar:
  - once en eski izlenmis ve koruma suresi dolmus videolar silinecek
  - sonra gerekirse daha eski hazir/yarim icerikler silinecek
- Uygulama:
  - en eski izlenmisleri one alan eviction mantigi eklendi
- Commit:
  - `63252782`
- Eksik:
  - `6 saat` watched TTL henuz ayri kural olarak baglanmadi

### 7. Standart Kota Profili

- Durum: `tamamlandi`
- Karar:
  - kullanici ekranda `3 GB` gordugunde efektif plan `4 GB` olarak
    uygulanacak
- Not:
  - bu `3+1 GB` standardi korunacak

### 8. Zamansal Yayin Akisi

- Durum: `sonraya alindi`
- Karar:
  - `100 bin` video toplu cache'e alinmayacak
  - yayin zamani gelen yeni videolar kuyruga alinacak
- Not:
  - bu alan rozetli filtre ve temel eviction kurallari kapandiktan sonra
    acilacak

## Siradaki Uygulama Paketi

1. Tam video + rozetli + `%70` + `6 saat` kombinasyonu icin yeniden smoke al.
2. Gerekirse ileride `yuksek begeni` sinifini ikinci aday havuz olarak ekle.
3. Zamansal yayin akisini rozetli aday havuzuna bagla.
