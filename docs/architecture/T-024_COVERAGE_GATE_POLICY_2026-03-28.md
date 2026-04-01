# T-024 Coverage Gate Policy

## Amac

`scripts/check_flutter_coverage.sh` icindeki placeholder coverage gate'ini kaldirip,
CI'nin dusuk coverage durumunu sahte yesil yerine gercek risk olarak gostermesini saglamak.

## Tespit edilen sorun

- Onceki policy:
  - `MIN_FLUTTER_COVERAGE_BASELINE=1.40`
  - `TARGET_FLUTTER_COVERAGE=70`
  - target zorunlu degil
- Sonuc:
  - `1.49%` coverage bile yesil kalabiliyordu
  - script `legacy baseline gate active` diyerek pratikte no-op davraniyordu

## Yeni policy

- `MIN_FLUTTER_COVERAGE_BASELINE=5.00`
- `TARGET_FLUTTER_COVERAGE=5.00`
- `ENFORCE_FLUTTER_COVERAGE_TARGET=1`

Bu seviye nihai hedef degil; ama `1.40%` placeholder esigin yerine
gercek fail ureten ilk anlamli taban cizgisi olarak secildi.

## Script degisiklikleri

- coverage raporu artik `coverage/coverage_gate_report.txt` olarak uretilir
- minimum baseline altina dusulurse fail eder
- target enforce aciksa target alti da fail eder
- CI artifact'i artik yalniz `lcov.info` degil, coverage gate raporunu da tasir

## Teknik not

Bu turda `flutter test --coverage` kosusu coverage gate'e gelmeden
`test/unit/modules/profile/liked_posts_controller_test.dart` icindeki
ayri bir derleme kirigina takildi. Bu coverage policy isinden bagimsiz debt olarak
`DEBT-003` altinda kayda alindi; bu iste duzeltilmedi.

## Yerel kapanis komutlari

```bash
bash -n scripts/check_flutter_coverage.sh
```

```bash
printf 'TN:\nSF:/tmp/pass.dart\nLF:100\nLH:5\nend_of_record\n' >/tmp/t024_coverage_pass.lcov
bash scripts/check_flutter_coverage.sh /tmp/t024_coverage_pass.lcov
```

```bash
printf 'TN:\nSF:/tmp/fail.dart\nLF:100\nLH:4\nend_of_record\n' >/tmp/t024_coverage_fail.lcov
bash scripts/check_flutter_coverage.sh /tmp/t024_coverage_fail.lcov
```

## Beklenen sonuc

- `5.00%` alti coverage artik fail uretir
- CI artifact'inda coverage gate raporu gorunur
- Coverage lane dusuk coverage'i gizleyen degil, gorunur hale getiren sinyal uretir
