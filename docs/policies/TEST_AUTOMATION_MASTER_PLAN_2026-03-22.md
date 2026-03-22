# TurqApp Master Automation Plan

## PR

Amaç: her push ve PR'da hizli ama gercek kalite kapisi.

Calisan workflow ve gate'ler:

- `ci.yml`
  - `Security Guards`
  - `Flutter Analyze + Test`
  - `Android Integration Smoke`
  - `iOS Integration Smoke`
  - `Functions Build + Unit`
  - `Firestore + Storage Rules`
  - `Worker Tests`

Ek kurallar:

- Integration smoke lane'leri otomatik fixture seed/reset kullanir.
- Coverage floor fail eder.
- Android ve iOS smoke merge-blocking check olarak alinmalidir.

## Nightly

Amaç: derin urun davranisi, uzun oturum, native playback, permission matrix, crash/load regresyonu.

Calisan workflow'lar:

- `product-depth-e2e.yml`
- `long-session-smoke.yml`
- `process-death-restore.yml`
- `native-playback-smoke.yml`
- `permission-os-matrix.yml`
- `crash-anr-matrix.yml`
- `k6-smoke.yml`

Beklenti:

- Tüm nightly lane'ler artifact uretmeli.
- Flake tespit edilirse retry degil, neden analizi yapilmali.

## Release

Amaç: release once zorunlu tum gercek urun akislari.

Calisan workflow:

- `release-gates.yml`

Zorunlu job'lar:

- `Android Release Master E2E`
- `Android Release Product Depth`
- `Android Release Process Death`
- `Android Release Permission OS Matrix`
- `iOS Release Product Depth`
- `iOS Release Process Death`
- `iOS Release Permission OS Matrix`

Not:

- Release adayi branch/tag publish edilmeden once bu workflow tam yesil olmadan deploy cikmamali.

## Post Deploy

Amaç: deploy sonrasi gercek ortam health kontrolu.

Calisan workflow:

- `post-deploy-feed-api-smoke.yml`

Tetikleme:

- manual
- reusable call
- `Release Gates` veya `Deploy Production` workflow tamamlandiginda otomatik

## Test Data

Otomasyon modeli:

- `functions/scripts/seed_integration_fixture.mjs`
- `functions/scripts/reset_integration_fixture.mjs`
- `scripts/integration_seed_helper.sh`
- default fixture: `integration_test/core/fixtures/smoke_seed.device_baseline.json`

Kurallar:

- Integration suite baslamadan seed uygulanir.
- Suite cikisinda reset calisir.
- CI ortaminda `FIREBASE_SERVICE_ACCOUNT_JSON` secret zorunludur.

## OS Permission Automation

Gercek OS seviyesinde kullanilan araclar:

- Android: `adb pm grant/revoke`, `appops`
- iOS: `xcrun simctl privacy`

Runner:

- `scripts/run_permission_os_matrix_suite.sh`

Flutter tarafinda dogrulanan testler:

- `integration_test/system/permission_os_denied_state_smoke_test.dart`
- `integration_test/system/permission_os_granted_state_smoke_test.dart`

## 10/10 Kriteri

Bir lane'in var olmasi yetmez. 10/10 icin:

- PR gate required check olarak aktif olmali
- release gate publish oncesi zorunlu olmali
- post-deploy smoke otomatik calismali
- fixture seed/reset secrets ile gercekten kullaniliyor olmali
- nightly lane'lerde flake orani olculebilmeli
- iOS ve Android parity duzenli izlenmeli
