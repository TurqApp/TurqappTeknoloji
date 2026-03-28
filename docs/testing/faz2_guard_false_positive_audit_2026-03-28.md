# F2-008 Guard False-Positive Audit ve Kalibrasyon

Tarih: `2026-03-28`
Durum: `Tamamlandi`

## Problem

`RISK-003` altindaki ana suphe, architecture guard'in bazi durumlarda gercek
kod degisimi olmadan CI'yi gereksiz kirmasiydi.

Ozellikle iki aday tespit edildi:

1. `Get.find` benzeri locator tokenlari yorum ve string iceriginden de
   sayilabiliyordu
2. `--files` ile verilen absolute path'ler local dogrulamada farkli davranis
   uretebiliyordu

## Tespit

Sentetik ornek:

- yorum satiri: `// Get.find should not count`
- string icerigi: `'Get.find in string should not count'`

Eski sayim davranisi:

- `LOCATOR_COUNT=2`

Bu, gercek locator artisi yokken `no_service_locator_outside_root` kuralinin
gereksiz fail verme riski oldugunu gosterdi.

## Yapilan Kalibrasyon

[check_architecture_guards.sh](/Users/turqapp/Desktop/TurqApp/scripts/check_architecture_guards.sh)
icinde:

1. `strip_non_code_for_token_scan()` eklendi
   - triple-quoted string
   - tek/cift tirnakli string
   - block comment
   - line comment
   icerikleri sayim oncesi temizleniyor

2. Su kurallar sanitize edilmis icerik ustunden calisacak hale getirildi:
   - `no_service_locator_outside_root`
   - `presentation_cannot_touch_infra`
   - `no_cross_feature_internal_imports`

3. `normalize_repo_path()` eklendi
   - `--files` ile verilen absolute path'ler repo-relative path'e normalize ediliyor
   - local ve CI davranisi hizalaniyor

## Dogrulama

Yapilan hedefli dogrulamalar:

- sentetik yorum/string orneginde eski ham sayim `2` olarak goruldu
- kalibrasyon sonrasi architecture guard script'i hedefli kosuda gecti
- docs guard gecti
- script diff temiz gecti

## Kazanimlar / Neler Duzeldi

- yorum ve string icindeki `Get.find` benzeri metinler artik sahte locator artisi
  olarak sayilmiyor
- yorum/blog/not satirlarindaki import ornekleri guard'i gereksiz tetiklemiyor
- local `--files` absolute path kullanimi ile CI relative path davranisi
  birbirine yaklasti
- `RISK-003` kapandi

## Bilincli Olarak Acik Birakilanlar

- Bu is guard'lari gevsetmedi; yalnizca metinsel noise kaynakli yanlis
  pozitifleri daraltti
- Coverage gate ve docs guard policy esikleri degismedi
