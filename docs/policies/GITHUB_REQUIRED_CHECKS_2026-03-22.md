# TurqApp GitHub Required Checks

Bu policy dosyasi repo icinde branch protection icin zorunlu tutulacak check adlarini sabitler.
GitHub branch protection ayari repo dosyalarindan dogrudan uygulanamaz; bu isimler GitHub Settings > Branch protection / Rulesets tarafinda required check olarak tanimlanmalidir.

## PR Required Checks

- `Security Guards`
- `Flutter Analyze + Test`
- `Android Integration Smoke`
- `iOS Integration Smoke`
- `Functions Build + Unit`
- `Firestore + Storage Rules`
- `Worker Tests`

## Release Required Checks

- `Android Release Master E2E`
- `Android Release Product Depth`
- `Android Release Process Death`
- `Android Release Permission OS Matrix`
- `iOS Release Product Depth`
- `iOS Release Process Death`
- `iOS Release Permission OS Matrix`

## Nightly Must Stay Green

- `Product Depth Android E2E`
- `Product Depth iOS E2E`
- `Android Long Session Smoke`
- `iOS Long Session Smoke`
- `Android Process Death Restore`
- `iOS Process Death Restore`
- `Android ExoPlayer Smoke`
- `iOS AVPlayer Smoke`
- `Android Crash ANR Matrix`
- `Android Permission OS Matrix`
- `iOS Permission OS Matrix`
- `k6 Smoke Load`

## Post Deploy Must Stay Green

- `Feed API Live Smoke`

## Notes

- `Release Gates` workflow tamamlaninca `Post Deploy Feed API Smoke` workflow'u otomatik tetiklenir.
- Bu policy dosyasi teknik kontrattir; GitHub UI / ruleset tarafindaki required-check listesi bununla birebir tutulmalidir.
