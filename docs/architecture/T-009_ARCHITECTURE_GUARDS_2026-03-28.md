# T-009 Architecture Guards Notu

## Amaç

Mevcut mimari borcu bir anda temizlemek değil, yeni erozyonu CI seviyesinde durdurmak.

## Uygulanan Yaklasim

Guard script'i tam repo borcunu fail etmiyor; degisen dosyalarda `base rev -> current` delta mantigi ile calisiyor.

Bu sayede:

- mevcut repo durumu donduruluyor
- yeni ihlal artislari fail ediyor
- false-positive riski ilk geciste kontrol altinda tutuluyor

## Script

- Script: `scripts/check_architecture_guards.sh`
- Urettigi artifact'lar:
  - `artifacts/architecture/architecture_guard_report.txt`
  - `artifacts/architecture/architecture_inventory.txt`
  - `artifacts/architecture/architecture_changed_files.txt`

## Fail-Fast Guardlar

- `legacy_folder_freeze`
  - `lib/Core`, `lib/Services`, `lib/Models` altina yeni Dart dosyasi eklenmesini engeller

- `no_new_part_sprawl`
  - yeni `*_facade_part.dart`, `*_fields_part.dart`, `*_class_part.dart` dosyalarini engeller

- `no_service_locator_outside_root`
  - degisen dosyalarda direct GetX locator kullanimi artarsa fail eder

- `presentation_cannot_touch_infra`
  - degisen presentation dosyalarinda Firebase veya `Core/Repositories` importu artarsa fail eder

- `no_cross_feature_internal_imports`
  - degisen feature dosyalarinda baska feature'in ic `controller/part/Common` importu artarsa fail eder

## CI Zinciri

`architecture-guards` isi:

- `flutter-quality` oncesi kosar
- fail olursa analyze/test adimlari baslamaz
- artifact olarak guard raporlarini saklar

## Not

Ilk surum bilincli olarak delta-tabanli kuruldu. Bu, mevcut repo borcunu bir anda patlatmadan yeni bozulmayi durdurmak icin secildi.
