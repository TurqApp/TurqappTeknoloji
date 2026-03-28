# F3-002 Android Smoke Artifact Export Zinciri

Tarih: `2026-03-28`
Durum: `Tamamlandi`

## Amac

`DEBT-006` kaydini kapatmak:

- Android emulator smoke senaryosu biterken uygulama paketi kalksa bile
- device-side QA artifact'larini host'a gercekten cekebilmek
- `host_stub` fallback'i zorunlu yol olmaktan cikarmak

## Yapilan Sertlestirme

Merkez degisiklik:

- [run_turqapp_test_smoke.sh](/Users/turqapp/Desktop/TurqApp/scripts/run_turqapp_test_smoke.sh)

Eklenen davranis:

1. Her smoke senaryosu baslamadan once Android artifact mirror watcher'i aciliyor
2. Watcher test calisirken `run-as` ile remote `integration_smoke` klasorunu poll ediyor
3. Uygulama JSON veya PNG artifact yazdigi anda host tarafa gecici dosya uzerinden kopyalaniyor
4. Kopyalanan JSON'lar `artifactStatus.source = android_device_export` ve `exported = true` olarak isaretleniyor
5. Senaryo bitince son bir sync daha deneniyor
6. Ancak senaryo artifact'i hala yoksa `host_stub` fallback yaziliyor

## Neler Duzeldi

- Artifact export zamani artik yalniz `flutter test` sonrasina bagli degil
- Paket suite sonunda kalksa bile, test sirasinda yazilan artifact host'a aynalanabiliyor
- Smoke report tarafinda gercek device export ile `host_stub` ayrimi gorunur hale geldi
- `DEBT-006` kapandi

## Teknik Notlar

- Poll araligi env ile ayarlanabilir:
  - `INTEGRATION_SMOKE_ANDROID_EXPORT_POLL_SECONDS`
- `adb` yolu env ile override edilebilir:
  - `ANDROID_ADB_BIN`
- Varsayilan deger:
  - `0.25`
- Host tarafina cekilen JSON'lar export sonrasi patch'lenir:
  - `artifactStatus.source = android_device_export`
  - `artifactStatus.exported = true`
  - varsa local screenshot yolu JSON'a geri yazilir

## Dogrulama

- `bash -n scripts/run_turqapp_test_smoke.sh` gecti
- `flutter test test/unit/services/integration_smoke_reporter_test.dart` gecti
- Izole fake `adb` + fake `flutter` harness gecti:
  - package install oldu
  - senaryo JSON'u remote smoke klasorune yazildi
  - package uninstall olmadan once background mirror watcher artifact'i host'a cekti
  - suite sonunda artifact JSON geride kaldi
- Export edilen artifact JSON icinde:
  - `artifactStatus.source = android_device_export`
  - `artifactStatus.exported = true`

## Sonuc

- Android smoke artifact export zinciri yalniz `host_stub` fallback'e dayanmiyor
- Device-side QA artifact'lari test kosusu sirasinda host'a cekilip rapora gercek export olarak yansitiliyor
