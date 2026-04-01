# F2-007 Cikarilan Smoke Akislarini Resmi Manifest'e Geri Alma

Tarih: `2026-03-28`
Durum: `Tamamlandi`

## Problem

`T-022` sonrasinda resmi auth/session/feed regression manifest'i asagidaki iki
smoke akisini icermiyordu:

- `integration_test/feed/feed_resume_test.dart`
- `integration_test/shorts/short_refresh_preserve_test.dart`

Bu iki akisin gecici olarak cikarilma nedeni `ADV-002` altinda kayitliydi.

## Yapilan Degisiklik

Kanonik manifest olan
[auth_session_feed_regression.txt](/Users/turqapp/Desktop/TurqApp/config/test_suites/auth_session_feed_regression.txt)
icine iki smoke akisi geri eklendi:

1. `integration_test/feed/feed_resume_test.dart`
2. `integration_test/shorts/short_refresh_preserve_test.dart`

Boylece resmi regression paketi artik tekrar su 6 akisla calisiyor:

- startup session restore
- signout state
- reauth restore
- feed primary bootstrap contract
- feed route replay resume
- short refresh preserve

## Neden Bu Artik Guvenli

- `F2-005` ile profile route replay zinciri stabilize edildi
- `F2-006` ile short route return / refresh preserve zinciri stabilize edildi
- Her iki akis da Android emulator ustunde tekil ve ikili smoke kosularinda yesile
  dondu

## Dogrulama

Resmi komut:

```bash
INTEGRATION_SMOKE_DEVICE_ID=emulator-5554 \
bash scripts/run_auth_session_feed_regression.sh
```

Ek regresyon dogrulamasi:

```bash
INTEGRATION_TEST_MANIFEST=/tmp/f2_006_dual_manifest.txt \
INTEGRATION_SMOKE_DEVICE_ID=emulator-5554 \
bash scripts/run_turqapp_test_smoke.sh
```

Sonuc:

- resmi auth/session/feed regression paketi yesil
- `feed_resume_test` ve `short_refresh_preserve_test` resmi pakette tekrar kosuyor

## Kazanimlar / Neler Duzeldi

- `ADV-002` tamamen kapandi
- Resmi auth/session/feed regression manifest'i yeniden tam hale geldi
- T-022 sonrasinda disari alinmis iki smoke akisi tekrar resmi sinyalin parcasi oldu

## Bilincli Olarak Acik Birakilanlar

- `RISK-007` altindaki `feed_blank_surface`, `permission-denied` ve benzeri QA
  sinyalleri bu isin konusu degil
- Manifest geri alimi tamamlandi, ama bu loglar ayri risk kaydi olarak izlenmeye
  devam ediyor
