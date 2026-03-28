# M1-003 Feed Profile Short Snapshot Repository Mekanik Cleanup

Tarih: `2026-03-29`
Durum: `Tamamlandi`

## Amac

`feed/profile/short` snapshot repository cluster'inda aktif functional cache
degisimlerine girmeden, yalniz mekanik `class/base/facade/fields/models`
part dagilimini azaltmak.

## Secilen mekanik hedefler

- `lib/Core/Repositories/feed_snapshot_repository.dart`
- `lib/Core/Repositories/profile_posts_snapshot_repository.dart`
- `lib/Core/Repositories/short_snapshot_repository.dart`

Silinen mikro part dosyalari:

- `lib/Core/Repositories/feed_snapshot_repository_base_part.dart`
- `lib/Core/Repositories/feed_snapshot_repository_class_part.dart`
- `lib/Core/Repositories/feed_snapshot_repository_facade_part.dart`
- `lib/Core/Repositories/feed_snapshot_repository_fields_part.dart`
- `lib/Core/Repositories/feed_snapshot_repository_models_part.dart`
- `lib/Core/Repositories/profile_posts_snapshot_repository_facade_part.dart`
- `lib/Core/Repositories/profile_posts_snapshot_repository_fields_part.dart`
- `lib/Core/Repositories/profile_posts_snapshot_repository_models_part.dart`
- `lib/Core/Repositories/short_snapshot_repository_facade_part.dart`
- `lib/Core/Repositories/short_snapshot_repository_fields_part.dart`
- `lib/Core/Repositories/short_snapshot_repository_models_part.dart`

## Uygulanan sadeleştirme

- `FeedSnapshotRepository`
  - `base`, `class`, `fields`, `facade` ve `models` bloklari ana dosyaya
    tasindi
  - `fetch`, `codec`, `visibility` ve `runtime` part'lari yerinde birakildi
- `ProfilePostsSnapshotRepository`
  - `fields`, `facade` ve `models` bloklari ana dosyaya tasindi
  - `codec` part'i yerinde birakildi
- `ShortSnapshotRepository`
  - `fields`, `facade` ve `models` bloklari ana dosyaya tasindi
  - `query`, `visibility` ve `runtime` part'lari yerinde birakildi

## Sayisal etki

- secilen mekanik repository seti: `14 -> 3`
- kaldirilan mikro part sayisi: `11`

## Neler duzeldi

- `feed/profile/short` snapshot repository davranisini okumak icin daha az
  dosya aciliyor
- aktif query/runtime/fetch functional diff'lerine dokunmadan mekanik giris
  daginimi azaldi
- snapshot cluster'indaki bir sonraki functional degisiklikler artik daha
  duzgun ana repository dosyalari uzerinden okunabilir

## Bilincli olarak dokunulmayan alanlar

- `feed_snapshot_repository_fetch_part.dart`
- `feed_snapshot_repository_runtime_part.dart`
- `profile_posts_snapshot_repository_codec_part.dart`
- `short_snapshot_repository_query_part.dart`
- `short_snapshot_repository_runtime_part.dart`
- dis-kapsam snapshot repository'leri

## Dogrulama

- hedefli `dart analyze`
- `git diff --check`
- docs single-source guard
- architecture guard

## Sonraki resmi adim

- `M1-004 | Part-sprawl debt kapanis guard'i ve final olcum`
