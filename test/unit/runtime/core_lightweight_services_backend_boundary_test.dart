import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lightweight Core services use backend boundary services', () async {
    final checkedFiles = <String>[
      'lib/Core/Services/job_saved_store.dart',
      'lib/Core/Services/notification_preferences_service.dart',
      'lib/Core/Services/story_music_library_service.dart',
      'lib/Core/Services/gif_library_service.dart',
      'lib/Core/Services/video_telemetry_service.dart',
      'lib/Core/Services/iz_birak_subscription_service.dart',
      'lib/Core/Services/moderation_config_service.dart',
    ];
    final violations = <String>[];

    for (final path in checkedFiles) {
      final source = await File(path).readAsString();
      if (source.contains('FirebaseFirestore.instance') ||
          source.contains('FirebaseFunctions.instance')) {
        violations.add(path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Lightweight Core services should use AppFirestore/AppCloudFunctions.',
    );
  });
}
