# T-026 Dokuman Tek-Kaynak Guard

Tarih: 2026-03-28

## Amac

`docs` dizininde yeniden tarihli plan, migration, handoff ve analiz yigini olusmasini otomatik guard ile engellemek.

## Uygulanan guard

- Yeni script: `scripts/check_docs_single_source.sh`
- CI baglantisi: `.github/workflows/ci.yml` icinde `Run Docs Single-Source Guard`
- Artifact ciktilari:
  - `artifacts/docs_guard/docs_single_source_report.txt`
  - `artifacts/docs_guard/docs_single_source_inventory.txt`
  - `artifacts/docs_guard/docs_changed_files.txt`

## Guard kurallari

- `docs` kokunde yalniz iki kanonik dosya izinli:
  - `docs/README.md`
  - `docs/TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md`
- `docs/architecture` altinda yalniz `T-*.md` gorev artifact'lari izinli.
- `docs/policies`, `docs/observability` ve `docs/testing` disindaki yeni dokuman yuzeyi ihlal sayilir.
- Kanonik plan disinda `plan`, `migration`, `handoff`, `analiz` isimli yeni dokumanlar ihlal sayilir.
- `docs/README.md` icinde:
  - kanonik belge listesi
  - tarihli plan/doc yigini yasagi
  - kanonik plan referansi
  zorunlu tutulur.

## Neden bu sekilde

- Mevcut mimari toparlama surecinde tek referans noktasi korunmak istendi.
- `docs/architecture/T-*.md` gorev artifact'lari saklandi; bunlar plan yigini degil, is kaniti olarak kabul edildi.
- Var olan `.DS_Store` gibi gizli dosyalar guard kapsaminda ihlal sayilmadi.

## Teknik dogrulama

- `bash -n scripts/check_docs_single_source.sh`
- `DOC_GUARD_ARTIFACT_DIR=/tmp/t026_docs_guard bash scripts/check_docs_single_source.sh --against HEAD --files docs/README.md,scripts/check_docs_single_source.sh,.github/workflows/ci.yml,docs/architecture/T-026_DOKUMAN_TEK_KAYNAK_GUARD_2026-03-28.md,docs/TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md`
