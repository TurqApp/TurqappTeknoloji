# T-028 Runtime Boundary

## Kapsam

- `DeviceSessionService` dogrudan feature kullanimi
- `NetworkAwarenessService` dogrudan feature kullanimi
- `UploadQueueService` dogrudan feature kullanimi

## Tasinan Sicak Yuzeyler

- `SignIn`
  - `sign_in_application_service.dart`
  - `sign_in_controller_auth_part.dart`
- `PostCreator`
  - `post_creator_controller_support_part.dart`
  - `post_creator_controller_flow_part.dart`
  - `creator_content_controller_media_part.dart`
- `Splash`
  - `splash_post_login_warmup.dart`
  - `splash_view_warm_part.dart`
  - `splash_dependency_registrar.dart`
- `Settings`
  - `settings.dart`
  - `settings_diagnostics_usage_part.dart`
  - `settings_diagnostics_actions_part.dart`
  - `permissions_view_playback_part.dart`

## Yeni Runtime Yuzeyi

- `lib/Runtime/feature_runtime_services.dart`
  - `DeviceSessionRuntimeService`
  - `NetworkRuntimeService`
  - `UploadQueueRuntimeService`

## Kabul Sonucu

- Secilen feature dosyalarinda dogrudan `DeviceSessionService.instance`
  izleri kaldirildi
- Secilen feature dosyalarinda dogrudan
  `NetworkAwarenessService.ensure/maybeFind` izleri kaldirildi
- Secilen feature dosyalarinda dogrudan `UploadQueueService.ensure`
  izleri kaldirildi
- Boundary delegasyonu hedefli unit test ile kilitlendi

## Dogrulama

- `dart analyze --no-fatal-warnings ...`
- `flutter test test/unit/modules/runtime_feature_services_test.dart`
- `bash scripts/check_architecture_guards.sh --against HEAD --files ...`
