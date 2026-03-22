# Release Gate Checklist (2026-03-15)

## Otomatik Testler
- `flutter analyze --no-fatal-infos`
- `flutter test`
- `bash scripts/run_integration_smoke.sh` (`RUN_INTEGRATION_SMOKE=1` ise)
- `functions/npm test`
- `functions/npm run test:rules`
- `functions/npm run build`
- `cloudflare-shortlink-worker/npm test`
- `bash scripts/check_repo_security_regressions.sh`
- `bash scripts/export_telemetry_threshold_report.sh` (`TELEMETRY_INPUT_FILE` varsa)

Tek komut:

```bash
bash scripts/run_release_gate_checks.sh
```

Fixture contract ile app smoke:

```bash
RUN_INTEGRATION_SMOKE=1 \
INTEGRATION_FIXTURE_FILE=integration_test/fixtures/smoke_fixture.example.json \
bash scripts/run_release_gate_checks.sh
```

Doğrudan smoke script:

```bash
INTEGRATION_FIXTURE_FILE=integration_test/fixtures/smoke_fixture.example.json \
bash scripts/run_integration_smoke.sh
```

Not:
- Script 5 smoke senaryosunu koşturur ve sonunda `artifacts/integration_smoke/*.json` dump'larının varlığını doğrular.
- Ardından `artifacts/integration_smoke_report_latest.json` toplu özet raporunu üretir.

Telemetry threshold report:

```bash
TELEMETRY_INPUT_FILE=tests/fixtures/telemetry_threshold_input.example.json \
TELEMETRY_REPORT_OUTPUT=artifacts/telemetry_threshold_report_latest.json \
bash scripts/export_telemetry_threshold_report.sh
```

Blocking threshold ihlalinde release gate'i düşürmek için:

```bash
TELEMETRY_INPUT_FILE=tests/fixtures/telemetry_threshold_input.example.json \
TELEMETRY_FAIL_ON_BLOCKING=1 \
bash scripts/run_release_gate_checks.sh
```

## k6 Testleri

### Smoke
- Amaç: script + endpoint + threshold hattını kısa profilde doğrulamak
- Tüm anlamlı `k6` modları için `ID_TOKEN` gerekir
- `ID_TOKEN` yoksa release gate script smoke turunu bilinçli olarak atlar

```bash
RUN_K6_SMOKE=1 \
ID_TOKEN=<firebase-id-token> \
bash scripts/run_release_gate_checks.sh
```

Auth'lu search smoke:

```bash
RUN_K6_SMOKE=1 \
K6_MODE=search_only \
ID_TOKEN=<firebase-id-token> \
bash scripts/run_release_gate_checks.sh
```

### Feed Only
- Amaç: feed okuma gecikmesi ve hata oranı
- Not: auth/context gerekir

```bash
k6 run \
  --env FIREBASE_PROJECT_ID=turqappteknoloji \
  --env ID_TOKEN=<firebase-id-token> \
  --env K6_PROFILE=feed_only \
  --env K6_MODE=feed_only \
  tests/load/k6_turqapp_load_test.js
```

### Interaction Only
- Amaç: like/view callable davranışı
- Not: `ID_TOKEN`, `TOGGLE_LIKE_ENDPOINT`, `RECORD_VIEW_ENDPOINT` gerekir

```bash
k6 run \
  --env FIREBASE_PROJECT_ID=turqappteknoloji \
  --env ID_TOKEN=<firebase-id-token> \
  --env TOGGLE_LIKE_ENDPOINT=<callable-url> \
  --env RECORD_VIEW_ENDPOINT=<callable-url> \
  --env K6_PROFILE=smoke \
  --env K6_MODE=interaction_only \
  tests/load/k6_turqapp_load_test.js
```

## Release Gate
- `flutter analyze --no-fatal-infos` yeşil
- `flutter test` yeşil
- App integration smoke yeşil
- Functions unit/rules/build yeşil
- Cloudflare worker testleri yeşil
- Security regression guard yeşil
- Telemetry threshold report üretilmiş
- Telemetry blocking issue yok, varsa gate bilinçli olarak kırılmış
- k6 smoke raporu üretilmiş
- Crashlytics kritik yeni issue yok
- Performance dashboard’da startup / first frame / error bandı stabil
- Staging smoke:
  - login
  - feed açılışı
  - short swipe
  - story görüntüleme
  - post paylaşma
  - follow / unfollow
  - DM açılışı

## Artefactlar
- `tests/load/k6_results_latest.json`
- `artifacts/telemetry_threshold_report_latest.json`
- `artifacts/integration_smoke/*.json`
- `artifacts/integration_smoke/*.png` (fail aninda destek varsa)
- `artifacts/integration_smoke_report_latest.json`
- `tests/load/k6_summary_smoke_search_only_latest.json`
- `tests/load/k6_summary_feed_only_feed_only_latest.json`
- `tests/load/k6_summary_smoke_interaction_only_latest.json`
