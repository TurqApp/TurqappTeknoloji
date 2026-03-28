# M1-001 Cache Snapshot Hot-Cluster Envanteri ve Freeze Siniri

Tarih: `2026-03-29`
Durum: `Tamamlandi`

## Amac

Aktif cache/snapshot calismasini plansiz genisleyen bir refactor yerine,
resmi olarak sinirlanmis bir mini-faza cevirmek.

Bu is kod davranisi degistirmez; yalnizca:

- hangi dosyalar mini-faz kapsaminda
- hangi dosyalar bilerek disarida
- sonraki islerin hangi yazma sinirina uyacagi

konularini sabitler.

## Mini Faz kapsami

Bu mini-faz icinde yazilabilecek resmi dosyalar: `22`

### A. CacheFirst cekirdegi

- `lib/Core/Services/CacheFirst/cache_first.dart`
- `lib/Core/Services/CacheFirst/cache_first_coordinator.dart`
- `lib/Core/Services/CacheFirst/typesense_cache_first_adapters.dart`
- `lib/Core/Services/CacheFirst/typesense_docid_hydration_adapter.dart`
- `lib/Core/Services/CacheFirst/cache_first_policy_registry.dart`
- `lib/Core/Services/CacheFirst/cache_scope_namespace.dart`

### B. Snapshot repository sicak kumesi

- `lib/Core/Repositories/feed_snapshot_repository_facade_part.dart`
- `lib/Core/Repositories/feed_snapshot_repository_fields_part.dart`
- `lib/Core/Repositories/feed_snapshot_repository_models_part.dart`
- `lib/Core/Repositories/feed_snapshot_repository_runtime_part.dart`
- `lib/Core/Repositories/profile_posts_snapshot_repository_facade_part.dart`
- `lib/Core/Repositories/profile_posts_snapshot_repository_fields_part.dart`
- `lib/Core/Repositories/profile_posts_snapshot_repository_models_part.dart`
- `lib/Core/Repositories/short_snapshot_repository_facade_part.dart`
- `lib/Core/Repositories/short_snapshot_repository_fields_part.dart`
- `lib/Core/Repositories/short_snapshot_repository_models_part.dart`
- `lib/Core/Repositories/short_snapshot_repository_query_part.dart`

### C. Session / cache temas noktasi

- `lib/Services/current_user_service.dart`
- `lib/Services/current_user_service_cache_part.dart`
- `lib/Services/current_user_service_cache_role_part.dart`
- `lib/Services/current_user_service_lifecycle_part.dart`
- `lib/Services/current_user_service_sync_role_part.dart`

## Bilincli olarak disarda birakilan kirli dosyalar

Bu mini-faz su an bu dosyalara yazmaz: `11`

- `lib/Core/Repositories/answer_key_snapshot_repository_support_part.dart`
- `lib/Core/Repositories/cikmis_sorular_snapshot_repository_pipeline_part.dart`
- `lib/Core/Repositories/job_home_snapshot_repository_fields_part.dart`
- `lib/Core/Repositories/market_snapshot_repository_models_part.dart`
- `lib/Core/Repositories/market_snapshot_repository_support_part.dart`
- `lib/Core/Repositories/notifications_snapshot_repository.dart`
- `lib/Core/Repositories/notifications_snapshot_repository_fields_part.dart`
- `lib/Core/Repositories/practice_exam_snapshot_repository_runtime_part.dart`
- `lib/Core/Repositories/question_bank_snapshot_repository_fields_part.dart`
- `lib/Core/Repositories/scholarship_snapshot_repository_state_part.dart`
- `lib/Core/Repositories/tutoring_snapshot_repository_pipeline_part.dart`

Sebep:

- bunlar farkli urun alanlarina dagiliyor
- ayni dalgada ele alinirlarsa mini-faz cache/snapshot yerine genel repo
  refactor'una kayar
- mevcut debt kapanisi icin once sicak cekirdek kume dar tutulmali

## Gozlenen mevcut degisim yogunlugu

Secilen mini-faz kapsaminda bugun:

- tracked degisim: `20` dosya
- untracked yeni dosya: `2`
- toplam scope yuzeyi: `22`

Diff yogunlugu en cok su alanlarda:

- `CacheFirst` adapter ve coordinator katmani
- feed/profile/short snapshot repository facade/fields/models/runtime/query
- `CurrentUserService` cache / sync / lifecycle temas noktasi

## Freeze siniri

Bu mini-faz boyunca:

- `M1-002` yalnizca `CacheFirst` ve `CurrentUserService` cache temas
  noktalarina yazabilir
- `M1-003` yalnizca feed/profile/short snapshot repository dosyalarina
  yazabilir
- yukaridaki `11` dis-kapsam dosyasi mini-faz revizyonu olmadan
  degistirilmeyecek
- education/market/notification snapshot dagilimi bu mini-faz icinde
  toplanmayacak

## Neler duzeldi

- Cache/snapshot calismasi artik "her yere dokunan kirli agac" gibi degil,
  resmi bir yazma siniri olan mini-faz olarak tanimli
- Sonraki iki teknik is icin hangi dosyalarin guvenli odak alani oldugu net
- Dis-kapsam snapshot repository'leri bilerek ayri tutuldugu icin plansiz
  genisleme riski azaldi

## Dogrulama

- `git status --short`
- hedefli `git diff --name-status`
- secilen scope icin `git diff --stat`

## Sonraki resmi adim

- `M1-002 | CacheFirst mekanik part sadeleştirmesi`
