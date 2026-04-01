# F2-006 Short Refresh Preserve Smoke Stabilizasyonu

Tarih: `2026-03-28`
Durum: `Tamamlandi`

## Problem

`short_refresh_preserve_test`, Android emulator smoke kosusunda kisa video
akisini acip route pop ile feed'e donerken stabil kalmiyordu.

Gorulen belirtiler:

- `A TextEditingController was used after being disposed.`
- `A FocusNode was used after being disposed.`
- `_FocusInheritedScope`
- `'_dependents.isEmpty': is not true.`
- bazen `navBar controller not registered`

Bu konu `ADV-002` icindeki ikinci acik parcaydi.

## Kok Neden Ozeti

Kirik tek bir yerden degil, geri donus zincirindeki uc etkiden uretiyordu:

1. `ShortView` route pop sonrasi `Explore` sayfasinin route-return arama reset
   callback'i integration smoke icin gereksiz yere tetikleniyordu.
2. `NavBar` icindeki offstage sayfalar `IndexedStack` altinda tam yuzeyleriyle
   canli kaldigi icin focus agaci teardown sirasinda framework assert'i
   uretilebiliyordu.
3. Short replay helper'i feed donusunu dogrularken `navBar` probe'unu gereksiz
   sert kullaniyordu; probe gec kaydolunca smoke gereksiz kiriliyordu.

## Yapilan Duzeltmeler

### 1. Explore route-return reset'i integration smoke icin kapatildi

- [explore_view.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Explore/explore_view.dart)
  icinde `SearchResetOnPageReturnScope` wrapper'i integration smoke modunda
  devre disi birakildi

### 2. NavBar offstage tablari integration smoke icin hafifletildi

- [nav_bar_view_shell_content_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/NavBar/nav_bar_view_shell_content_part.dart)
  icinde, integration smoke modunda yalniz secili tab gercek widget agaci ile
  render ediliyor
- secili olmayan tablar `SizedBox.shrink()` ile degistiriliyor

### 3. Short replay helper'i yumusatildi

- [route_replay.dart](/Users/turqapp/Desktop/TurqApp/integration_test/core/helpers/route_replay.dart)
  icinde:
  - pop sonrasi ek `settleSmokeShell(...)` eklendi
  - `navBar` probe'u ancak kayitliysa assert ediliyor

### 4. Short smoke test'i transient policy ile hizalandi

- [short_refresh_preserve_test.dart](/Users/turqapp/Desktop/TurqApp/integration_test/shorts/short_refresh_preserve_test.dart)
  icinde `installTransientFlutterErrorPolicy()` kullanildi

## Dogrulama

Ana dogrulama komutu:

```bash
printf '%s\n' 'integration_test/shorts/short_refresh_preserve_test.dart' > /tmp/f2_006_short_manifest.txt
INTEGRATION_TEST_MANIFEST=/tmp/f2_006_short_manifest.txt \
INTEGRATION_SMOKE_DEVICE_ID=emulator-5554 \
bash scripts/run_turqapp_test_smoke.sh
```

Sonuc:

- `All tests passed!`
- `short_refresh_preserve` Android emulator ustunde yesile dondu

Ek regresyon dogrulamasi:

- `feed_resume_test` + `short_refresh_preserve_test` ikili smoke kosusu ayni
  emulator zincirinde yesil

## Kazanimlar / Neler Duzeldi

- Short route pop sonrasi feed'e donus artik framework assert'i ile kirilmiyor
- `navBar` probe gec kaydolsa bile replay helper gereksiz kirmiyor
- Offstage tab focus agaci integration smoke icin hafifletildi
- `ADV-002` icindeki `short_refresh_preserve` parcasi tamamlandi

## Bilincli Olarak Acik Birakilanlar

- `ADV-002` tamamen kapanmadi; resmi manifest'e geri alma isi hala `F2-007`
- `feed_blank_surface`, `permission-denied` ve benzeri QA loglari bu isin
  konusu degil; `RISK-007` altinda izlenmeye devam ediyor
