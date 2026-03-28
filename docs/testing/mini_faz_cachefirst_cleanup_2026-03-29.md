# M1-002 CacheFirst Mekanik Part Sadelestirmesi

Tarih: `2026-03-29`
Durum: `Tamamlandi`

## Amac

`CacheFirst` cluster'indeki canli functional diff'lere girmeden, dusuk riskli
mekanik `base/facade` part dagilimini azaltmak.

## Secilen dusuk riskli hedef

- `lib/Core/Services/CacheFirst/warm_launch_pool.dart`

Silinen mikro part dosyalari:

- `lib/Core/Services/CacheFirst/warm_launch_pool_facade_part.dart`
- `lib/Core/Services/CacheFirst/warm_launch_pool_members_part.dart`

## Uygulanan sadeleştirme

- `_WarmLaunchPoolBase` tanimi ana dosyaya tasindi
- `maybeFindWarmLaunchPool()` ve `ensureWarmLaunchPool()` ana dosyaya tasindi
- facade extension metotlari ana dosyaya tasindi
- `IndexPoolStore` uzerindeki davranis oldugu gibi korundu

## Sayisal etki

- mekanik giris seti: `3 -> 1`
- kaldirilan mikro part sayisi: `2`

## Neler duzeldi

- `WarmLaunchPool` davranisini okumak icin artik tek dosya yeterli
- `CacheFirst` cluster'indeki gecis/facade yuzeyi daha okunur hale geldi
- canli cache/snapshot functional diff'lerine girmeden olculu bir part-sprawl
  azalmasi saglandi

## Bilincli olarak dokunulmayan alanlar

- `cache_first_coordinator.dart`
- `typesense_cache_first_adapters.dart`
- `typesense_docid_hydration_adapter.dart`
- `cache_first_policy_registry.dart`
- `cache_scope_namespace.dart`

Bu dosyalar aktif functional cache calismasinin parcasi oldugu icin bu iste
mekanik merge disinda bir duzenleme yapilmadi.

## Dogrulama

- hedefli `dart analyze`
- `git diff --check`
- docs single-source guard
- architecture guard

## Sonraki resmi adim

- `M1-003 | Feed/Profile/Short snapshot repository mekanik cleanup`
