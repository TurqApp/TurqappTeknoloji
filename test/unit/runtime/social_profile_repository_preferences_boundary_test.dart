import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('social profile repositories use local preference repository', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/profile_stats_repository.dart',
      'lib/Core/Repositories/profile_stats_repository_cache_part.dart',
      'lib/Core/Repositories/follow_repository.dart',
      'lib/Core/Repositories/follow_repository_cache_part.dart',
      'lib/Core/Repositories/follow_repository_action_part.dart',
      'lib/Core/Repositories/verified_account_repository.dart',
      'lib/Core/Repositories/verified_account_repository_cache_part.dart',
      'lib/Core/Repositories/notification_preferences_repository.dart',
      'lib/Core/Repositories/notification_preferences_repository_models_part.dart',
      'lib/Core/Repositories/notification_preferences_repository_cache_part.dart',
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
      reason:
          'Social/profile repositories should use LocalPreferenceRepository.',
    );
  });
}
