# T-012 CurrentUserService Role Split

## Amac

`CurrentUserService` icindeki ana sorumluluklari daha gorunur ve testlenebilir
rollere ayirmak:

- auth
- cache
- sync
- account-center

## Yapilan Degisiklik

- `lib/Services/current_user_service_auth_role_part.dart`
  - auth state, effective identity ve token refresh sorumlulugu
- `lib/Services/current_user_service_cache_role_part.dart`
  - current user cache key, cache read/write ve sessiz loglama sorumlulugu
- `lib/Services/current_user_service_sync_role_part.dart`
  - initialize, firebase sync, merged user data kurma ve sync lifecycle sorumlulugu
- `lib/Services/current_user_service_account_center_role_part.dart`
  - exclusive session / account-center etkilesimi ve session displacement sorumlulugu

Mevcut facade korunmustur; dis cagrilar kirilmadan kalir.

## Test

`test/unit/services/current_user_service_role_split_test.dart`

Kapsam:

- role part deklarasyonlari mevcut mu
- auth/cache role varsayilan signed-out davranisi stabil mi
- sync/account-center role nesneleri construct edilebiliyor mu

## Teknik Dogrulama

- `dart analyze --no-fatal-warnings lib/Services/current_user_service.dart lib/Services/current_user_service_auth_part.dart lib/Services/current_user_service_cache_part.dart lib/Services/current_user_service_sync_part.dart lib/Services/current_user_service_lifecycle_part.dart lib/Services/current_user_service_auth_role_part.dart lib/Services/current_user_service_cache_role_part.dart lib/Services/current_user_service_sync_role_part.dart lib/Services/current_user_service_account_center_role_part.dart test/unit/services/current_user_service_role_split_test.dart`
- `flutter test test/unit/services/current_user_service_role_split_test.dart`
- `git diff --check -- ...`

## Beklenen Kazanim

- `CurrentUserService` artik tek parca degil, isimli roller uzerinden okunabilir
- sonraki `T-013` ve `T-014` islerinde hedefli degisiklik yapmak daha kolay
- account-center ve session displacement davranisi ayri bir sahiplik kazandi
