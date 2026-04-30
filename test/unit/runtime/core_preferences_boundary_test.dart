import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LocalPreferenceRepository owns SharedPreferences singleton access',
      () async {
    const approvedOwner =
        'lib/Core/Repositories/local_preference_repository.dart';
    final violations = <String>[];

    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final source = await file.readAsString();
      if (!source.contains('SharedPreferences.getInstance')) continue;
      if (normalizedPath == approvedOwner) continue;
      violations.add(normalizedPath);
    }

    expect(
      violations,
      isEmpty,
      reason: 'SharedPreferences singleton access should stay behind '
          'LocalPreferenceRepository.',
    );
  });

  test('core app-level services use local preference repository', () async {
    final checkedFiles = <String>[
      'lib/Core/Localization/app_language_service.dart',
      'lib/Core/Localization/app_language_service_runtime_part.dart',
      'lib/Core/Services/network_awareness_service.dart',
      'lib/Core/Services/network_awareness_service_storage_part.dart',
      'lib/Core/notification_service.dart',
      'lib/Core/notification_service_setup_part.dart',
      'lib/Core/notification_service_message_part.dart',
      'lib/Core/Repositories/config_repository.dart',
      'lib/Core/Repositories/config_repository_storage_part.dart',
      'lib/Core/Services/startup_surface_order_service.dart',
      'lib/Core/Services/draft_service_library.dart',
      'lib/Core/Services/draft_service_storage_part.dart',
      'lib/Core/Services/draft_service_drafts_part.dart',
      'lib/Core/Services/upload_queue_service.dart',
      'lib/Core/Services/upload_queue_service_persistence_part.dart',
      'lib/Core/Services/user_profile_cache_service.dart',
      'lib/Core/Services/user_profile_cache_service_storage_part.dart',
      'lib/Core/Services/profile_posts_cache_service.dart',
      'lib/Core/Services/feed_diversity_memory_service.dart',
      'lib/Services/device_session_service.dart',
      'lib/Services/current_user_service.dart',
      'lib/Services/current_user_service_cache_part.dart',
      'lib/Services/current_user_service_account_part.dart',
      'lib/Services/current_user_service_sync_role_part.dart',
      'lib/Services/account_center_service.dart',
      'lib/Services/account_center_service_storage_part.dart',
      'lib/Services/offline_mode_service.dart',
      'lib/Services/offline_mode_service_queue_part.dart',
    ];
    final violations = <String>[];

    for (final path in checkedFiles) {
      final source = await File(path).readAsString();
      if (!source.contains('SharedPreferences.getInstance')) continue;
      violations.add(path);
    }

    expect(
      violations,
      isEmpty,
      reason: 'Core app-level services should use LocalPreferenceRepository.',
    );
  });
}
