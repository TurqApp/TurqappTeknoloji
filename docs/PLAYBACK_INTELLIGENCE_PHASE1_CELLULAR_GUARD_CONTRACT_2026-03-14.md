# Playback Intelligence Phase 1 Cellular Guard Contract

Bu dokuman Faz 1 icin mobil veri davranisinin sozlesmesini tanimlar.

## 1. Amac

Cellular guard'in amaci oynatmayi tamamen kapatmak degil, arka plan islerini sinirlayip playback'i korumaktir.

## 2. Kurallar

### Wi-Fi
- background prefetch acik
- playlist fetch acik
- on-demand segment fetch acik

### Cellular
- background prefetch kapali
- playlist fetch acik
- on-demand segment fetch acik
- sadece cache miss playback korumasi icin kullanilir

### Cellular + pauseOnCellular
- background prefetch kapali
- playlist fetch acik
- on-demand segment fetch kapali
- cache-only mode acik

### Offline
- tum fetch yollar kapali
- cache-only mode acik

## 3. Faz 1 Siniri

Bu fazda:
- mobile seed mode agresif acilmaz
- segment mikro-yonetimi yok
- user intent / dwell / mute / fullscreen sinyalleri devreye alinmaz

## 4. Proxy Davranisi

- playlist cache miss:
  - baglanti yoksa reddedilir
  - aksi halde policy izin veriyorsa agdan cekilir

- segment cache miss:
  - Wi-Fi'da agdan cekilir
  - Cellular'da sadece cache-only mode kapaliysa agdan cekilir
  - `pauseOnCellular == true` veya offline ise reddedilir
