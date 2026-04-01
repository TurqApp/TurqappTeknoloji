# M1-004 Part-Sprawl Debt Kapanis Guard'i ve Final Olcum

Tarih: `2026-03-29`
Durum: `Tamamlandi`

## Amac

`DEBT-001` kaydini sadece refactor commit'leriyle degil, tekrar buyumeyi
engelleyen resmi bir guard ve final olcum kaydi ile kapatmak.

## Eklenen guard

- Script: `scripts/check_part_sprawl_budget.sh`
- Policy: `config/quality/part_sprawl_budget_targets.txt`
- CI adimi: `Run Part-Sprawl Budget Guard`

Guard tracked dosyalar uzerinden calisir:

- `git ls-files 'lib/**/*_part.dart'`
- yalniz su mikro part tipleri sayilir:
  - `_facade_part.dart`
  - `_fields_part.dart`
  - `_class_part.dart`
  - `_base_part.dart`
  - `_members_part.dart`

Bu sayede aktif local kirli worktree, resmi debt sinyalini bozmaz.

## Final olcum

### Legacy T-030 alt-kumesi

`T-030` yalnizca `facade/fields/class` part turlerini izliyordu.

- baslangic: `523`
- guncel: `489`
- net dusus: `34`

### Genisletilmis tracked mikro part baseline'i

`M1-004` artik `facade/fields/class/base/members` mikro part tiplerini birlikte
izler.

- `micro_part_total = 613`
- suffix dagilimi:
  - `_facade_part.dart = 195`
  - `_fields_part.dart = 170`
  - `_class_part.dart = 124`
  - `_base_part.dart = 122`
  - `_members_part.dart = 2`

## Guard edilen sicak kumeler

- `micro_part_total = 613 / 613`
- `cache_snapshot_hot = 0 / 0`
- `startup_auth_session_hot = 0 / 0`
- `profile_social_hot = 4 / 4`
- `feed_playback_hot = 37 / 37`

Bu guard'lar tekrar buyumeyi dogrudan fail ettirir.

## Watch hedefleri

Su cluster'lar su an fail ettirmez; artifact raporunda gorunur:

- `education_pasaj_watch = 182 / 190`
- `core_services_watch = 94 / 100`
- `profile_settings_admin_watch = 5 / 8`

## Neler duzeldi

- Part-sprawl debt'i artik "goruluyor ama kontrol edilmiyor" durumunda degil
- Daha once daralttigimiz sicak kumeler tekrar buyurse CI fail verecek
- Buyuk kalan mikro part birikimleri de watch hedefi olarak raporlanacak
- `DEBT-001` kaydi kapanabilir hale geldi

## Dogrulama

- `bash -n scripts/check_part_sprawl_budget.sh`
- `bash scripts/check_part_sprawl_budget.sh`
- `git diff --check`
- docs single-source guard

## Not

Bu kapanis, repo genelinde part dosyalarinin az oldugu anlamina gelmez.
Anlami sunlar:

- debt artik olculu
- tekrar buyume yolu guard altinda
- buyuk cluster'lar artik raporlu
