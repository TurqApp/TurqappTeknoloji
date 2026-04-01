# F3-001 Task Isolation / Worktree Drift Guard

Tarih: `2026-03-28`
Durum: `Tamamlandi`

## Amac

Aktif is disinda kirli dosya birikmesini ve task sirasinda `HEAD` kaymasini
sessiz risk olmaktan cikarmak.

## Teslimat

Yeni local guard script'i:

- `scripts/check_task_isolation.sh`

Script su iki sinyali fail eder:

- beklenen `HEAD` ile mevcut `HEAD` farkliysa
- izin verilen dosya listesi disinda kirli dosya varsa

## Kullanim

Ornek:

```bash
TASK_ISOLATION_ARTIFACT_DIR=/tmp/f3_001_task_isolation \
  bash scripts/check_task_isolation.sh \
  --expected-head d634a718 \
  --allow scripts/check_task_isolation.sh,docs/testing/faz3_task_isolation_guard_2026-03-28.md,docs/TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md
```

## Uretilen Artifact'lar

- `task_isolation_report.txt`
- `task_isolation_dirty_paths.txt`
- `task_isolation_allowlist.txt`
- `task_isolation_unrelated_paths.txt`

## Dogrulama

- `bash -n scripts/check_task_isolation.sh`
- dar allowlist kosusu:
  - yalniz F3-001 dosyalari allowlist'e verildi
  - repo icindeki aktif baska kirli dosyalar nedeniyle sonuc `FAIL`
  - boylece allowlist disi kirli dosya tespitinin calistigi goruldu
- baseline allowlist kosusu:
  - mevcut tum kirli yol listesi allowlist'e verildi
  - `expected-head` mevcut `HEAD` ile eslesti
  - sonuc `PASS`
- docs single-source guard gecti

## Sonuc

- `RISK-008` kapandi
- aktif is disi kirli dosya artik tekrar uretilebilir sekilde fail ettirilebiliyor
- `HEAD` drift artik raporsuz bir durum degil
- mevcut worktree'de baska aktif degisiklikler olsa bile bunlar artik sessiz
  degil; guard raporunda ayri gorunur hale geliyor
