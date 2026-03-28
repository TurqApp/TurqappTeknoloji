# F3-005 Surface Budget Guard ve Cluster Hedef Listesi

Tarih: `2026-03-29`
Durum: `Tamamlandi`

## Amac

`DEBT-002` kaydini sadece envanter olarak birakmayip, tekrar buyuyen repo
yuzeyini gorunur ve fail-eden bir guard altina almak.

## Eklenen guard

- Script: `scripts/check_repo_surface_budget.sh`
- Policy: `config/quality/repo_surface_budget_targets.txt`
- CI adimi: `Run Repo Surface Budget Guard`

Guard tracked dosyalar uzerinden calisir:

- sayim icin `git ls-files 'lib/**/*.dart'` kullanilir
- boylece aktif local/untracked calisma dosyalari resmi budget sinyalini kirletmez

## Guard edilen sicak kumeler

### 1. Repo toplam yuzeyi

- ad: `repo_total`
- mode: `guard`
- max: `2750`
- guncel: `2731`

### 2. Startup / Auth / Session hot cluster

- ad: `startup_auth_session_hot`
- mode: `guard`
- max: `21`
- guncel: `21`
- kapsam:
  - `current_user_service*`
  - `account_center_service*`
  - `sign_in_controller*`

### 3. Profile / Social hot cluster

- ad: `profile_social_hot`
- mode: `guard`
- max: `57`
- guncel: `57`
- kapsam:
  - `Profile/MyProfile/**`
  - `SocialProfile/**`

### 4. Feed / Playback hot cluster

- ad: `feed_playback_hot`
- mode: `guard`
- max: `33`
- guncel: `33`
- kapsam:
  - `agenda_controller.dart`
  - `FloodListing/**`
  - `TopTags/**`
  - `short_controller.dart`
  - `StoryHighlights/**`

## Watch hedefleri

Bu kumeler su an fail ettirmez; ama raporda gorunur:

- `education_pasaj_watch`
  - max: `700`
  - guncel: `689`
- `core_services_watch`
  - max: `445`
  - guncel: `437`
- `market_job_creator_watch`
  - max: `205`
  - guncel: `192`

## Neler duzeldi

- Repo yuzeyi artik sadece tarihli bir sayim degil; CI'da fail eden resmi bir
  budget guard'a donustu.
- Daha once sadeleştirilen sicak kumeler tekrar buyurse bu durum aninda
  gorunur olacak.
- Aktif local worktree kirleri tracked budget sinyaline karismayacak.
- `DEBT-002` kaydi "takip ediyoruz ama korumuyoruz" durumundan cikti.

## Dogrulama

- `bash -n scripts/check_repo_surface_budget.sh`
- `bash scripts/check_repo_surface_budget.sh`
- `git diff --check`
- docs single-source guard

## Bilincli olarak acik birakilan alanlar

- `DEBT-001` kapanmadi; part-sprawl hala ayri bir debt olarak acik
- watch cluster'lar su an yalniz gorunur; fail seviyesine tasinmalari yeni
  dalga gerektirir
