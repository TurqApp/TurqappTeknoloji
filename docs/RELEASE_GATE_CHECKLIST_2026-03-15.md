# Release Gate Checklist (2026-03-15)

## Otomatik Testler
- `flutter analyze --no-fatal-infos`
- `flutter test`
- `functions/npm test`
- `functions/npm run test:rules`
- `functions/npm run build`
- `cloudflare-shortlink-worker/npm test`
- `bash scripts/check_repo_security_regressions.sh`

Tek komut:

```bash
bash scripts/run_release_gate_checks.sh
```

## k6 Testleri

### Smoke
- Amaç: script + endpoint + threshold hattını kısa profilde doğrulamak
- Varsayılan mod: `search_only`

```bash
RUN_K6_SMOKE=1 \
K6_MODE=search_only \
bash scripts/run_release_gate_checks.sh
```

### Feed Only
- Amaç: feed okuma gecikmesi ve hata oranı
- Not: anlamlı sonuç için auth/context gerekir

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
- Functions unit/rules/build yeşil
- Cloudflare worker testleri yeşil
- Security regression guard yeşil
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
- `tests/load/k6_results.json`
- `tests/load/k6_summary_smoke_search_only_latest.json`
- `tests/load/k6_summary_feed_only_feed_only_latest.json`
- `tests/load/k6_summary_smoke_interaction_only_latest.json`
