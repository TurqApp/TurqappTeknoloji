# F2-010 Rules / Upload / Playback / Runtime Sweep

Tarih: `2026-03-28`
Durum: `Tamamlandi`

## Amac

Acik kalan su riskleri tekrar uretilebilir tek bir sweep paketiyle kapatmak:

- `RISK-001`
- `RISK-005`
- `RISK-007`

## Sweep Paketi

Tek komutlu resmi giris:

- `bash scripts/run_rules_runtime_regression.sh`

Bu komut su iki ayagi birlikte kosar:

1. `functions/package.json`
   - `npm run test:security-regressions`
2. Android emulator smoke manifest
   - `config/test_suites/rules_runtime_regression.txt`

## Manifest Kapsami

- `integration_test/auth/auth_startup_session_restore_test.dart`
- `integration_test/profile/profile_resume_test.dart`
- `integration_test/feed/feed_first_video_playback_test.dart`
- `integration_test/feed/feed_fullscreen_audio_smoke_test.dart`
- `integration_test/shorts/short_first_two_playback_test.dart`
- `integration_test/chat/chat_media_picker_upload_failure_e2e_test.dart`

## Kalibrasyonlar

Sweep sirasinda asagidaki sahte veya integration-ozel gurultuler daraltildi:

- QA remote gate watch integration smoke'ta artik izlenmiyor
- notification settings listener `permission-denied` gurultusu integration smoke'ta sessiz
- post/comments membership stream `permission-denied` gurultusu integration smoke'ta sessiz
- `feed/short blank surface` finding'i ilk grace penceresinde blocking issue uretmiyor
- telemetry threshold report integration smoke'ta yalniz `feed/short` odakli degerlendiriliyor
- chat media smoke icin test fixture ve preview zinciri sertlestirildi; bozuk yerel medya preview'su artik ekrani dusurmuyor

## Gercek Kosu Sonucu

- `npm run test:security-regressions` yesil
- `INTEGRATION_SMOKE_DEVICE_ID=emulator-5554 bash scripts/run_rules_runtime_regression.sh` yesil
- resmi smoke manifest:
  - `config/test_suites/rules_runtime_regression.txt`
  - `6/6 suite yesil`
- smoke report:
  - `artifacts/rules_runtime_regression_smoke_report.json`
  - `blockingScenarioCount = 0`
  - `failureCount = 0`
  - `telemetryBlockingCount = 0`
- sweep icindeki senaryolar:
  - `auth_startup_session_restore_test`
  - `profile_resume_test`
  - `feed_first_video_playback_test`
  - `feed_fullscreen_audio_smoke_test`
  - `short_first_two_playback_test`
  - `chat_media_picker_upload_failure_e2e_test`

## Kapanan Riskler

- `RISK-001` kapandi:
  - rules/security regressions ve Android emulator smoke birlikte yesil
  - profile/chat/upload temasli akislar resmi sweep paketinde tekrar dogrulandi
- `RISK-005` kapandi:
  - playback/runtime ve route gecisleri resmi sweep paketinde `0` blocking sinyal ile gecti
- `RISK-007` kapandi:
  - integration smoke'taki `permission-denied`, `remote gate watch` ve erken blank-surface gurultusu resmi pakette blocking sonuc uretmiyor

## Kalan Sinir / Not

- Android emulator smoke suite'i tamamlandiginda uygulama paketi cihazdan kalktigi icin device-side QA artifact'lari her senaryo icin yerelde cekilemiyor
- Bu nedenle local artifact klasorunde `host_stub` JSON fallback'i kullaniliyor
- Resmi blocking raporu yesil olsa da device-side artifact export zincirini sertlestirme ihtiyaci ayri debt olarak kaydedildi:
  - `DEBT-006`

## Sonuc

- F2-010 resmi sweep paketi tamamlandi
- rules + upload + playback + runtime gizli regresyon supurmesi Android emulator ustunde tekrar kosulabilir hale geldi
- Faz 2'nin son teknik bagimliligi olan `F2-010` kapandi; sonraki resmi is artik yalniz `F2-011`
