# Playback Intelligence Phase 1 Policy Modes

Bu dokuman Faz 1 icin aktif playback mode state machine sozlesmesini tanimlar.

## 1. Modlar

### bootstrap
- Kosul: cihaz bagli ve `isBootstrap == true`
- Hedef: ilk route ve ilk medya deneyimini hizli acmak
- Kurallar:
  - playlist fetch acik
  - on-demand segment fetch acik
  - background prefetch acik
  - startup window kucuk ve sabit

### wifi_fill
- Kosul: cihaz Wi-Fi'da, bootstrap disinda
- Hedef: gorunur pencere ve yuksek olasilikli medyayi sicak tutmak
- Kurallar:
  - background prefetch acik
  - on-demand segment fetch acik
  - playlist fetch acik

### cellular_guard
- Kosul: cihaz mobil veride
- Hedef: oynatmayi korurken veri tuketimini sinirlamak
- Kurallar:
  - background prefetch kapali
  - on-demand segment fetch sadece playback korumasi icin acik
  - startup/ahead window dar

### offline_guard
- Kosul: baglanti yok
- Hedef: sadece local cache ile oynatma denemek
- Kurallar:
  - tum fetch kapali
  - cache-only mode acik

## 2. Faz 1 Gecis Kurali

Gecis onceligi:
1. offline_guard
2. bootstrap
3. wifi_fill
4. cellular_guard

Not:
- Faz 1'de hysteresis yok
- Faz 1'de thermal/battery/low-data-mode bridge yok
- Faz 1'de user intent sinyali mode degistirmez; sadece pencere boyutlari sonra etkiler

## 3. Faz 1 Siniri

Bu state machine:
- yeni native downloader acmaz
- background job orkestrasyonu yapmaz
- sadece mevcut Flutter policy kararlarini merkezi hale getirir
