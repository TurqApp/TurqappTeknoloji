# Faz 2 Truth-Run Baseline

Uretim tarihi: `2026-03-28`

## Kapsam

Bu artifact, Faz 2'yi varsayim yerine olculu mevcut durumla baslatmak icin olusturuldu.

## Repo Durumu

- branch: `codex/playback-baseline-cdf29769`
- baslangic commit: `648fe0c1`
- bitis commit: `c4fb4171`
- not: kosu sirasinda repo HEAD disaridan ilerledi

Kosunun sonunda benden bagimsiz olarak kirli gorunen dosyalar:

- `lib/Modules/Profile/MyProfile/profile_view.dart`
- `lib/Modules/Profile/MyProfile/profile_view_shell_content_part.dart`
- `lib/Modules/SocialProfile/social_profile.dart`
- `lib/Modules/SocialProfile/social_profile_content_part.dart`

## Kod Tabanı Metriği

- `lib` Dart dosyasi: `2768`
- `test + integration_test` Dart dosyasi: `142`
- `functions/src` TypeScript dosyasi: `29`

## Coverage Truth-Run

Komut:

- `flutter test --coverage`
- `FLUTTER_COVERAGE_REPORT_FILE=/tmp/f2_001_coverage_gate_report.txt bash scripts/check_flutter_coverage.sh coverage/lcov.info`

Sonuc:

- full `flutter test --coverage`: `gecti`
- coverage toplam: `4.55%`
- coverage gate minimum/target: `5.00%`
- coverage gate sonucu: `fail`

Anlamı:

- coverage lane derleme ve test seviyesinde yesil
- ama kalite esigi hala kirmizi

## Android Emulator Smoke Truth-Run

Komut:

- `INTEGRATION_SMOKE_DEVICE_ID=emulator-5554 bash scripts/run_auth_session_feed_regression.sh`

Ilk deneme:

- `emulator-5554` bagli degildi
- AVD `TurqApp_Pixel_8` boot edilerek kosu tekrarlandi

Ikinci deneme sonucu:

- resmi smoke paketi: `gecti`
- suite sayisi: `4/4`
- cihaz: `emulator-5554`

Kosu sirasinda gozlenen bulgular:

- `feed_blank_surface` route=`/NavBarView`
- `REMOTE_GATE_WATCH_ERROR` ve birden fazla `cloud_firestore/permission-denied` logu
- `telemetry_local_hit_ratio_critical` loglari: `feed`, `market`, `profile`
- `CurrentUserAuthRole.resolveAuthUser` auth restore timeout logu
- izin loglari: `notifications`, `camera`, `microphone`, `photos`

## Faz 2 Baslangic Blokaj Adaylari

1. Coverage gate hala `4.55%` ile esigin altinda.
2. Android emulator smoke yesil olsa da authenticated feed acilisinda `feed_blank_surface` ve `permission-denied` izleri var.
3. Task kosusu sirasinda repo HEAD disaridan ilerledi ve worktree plan disi dosyalar aldi.

## Faz 2 Gorevlerine Esleme

- coverage esik kirmizisi:
  - `F2-001` baseline kaydi
- authenticated feed blank surface / permission-denied:
  - `F2-009`
  - `F2-010`
- repo drift / task isolation riski:
  - `RISK-008` olarak izlenecek

## Hukum

F2-001 kabul kriteri saglandi:

- fresh coverage sonucu olculdu
- Android emulator smoke sonucu olculdu
- ilk gercek blokaj adaylari kayda alindi
