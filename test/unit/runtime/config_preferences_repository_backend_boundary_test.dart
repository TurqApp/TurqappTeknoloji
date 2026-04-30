import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('config preference moderation repositories use AppFirestore', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/config_repository.dart',
      'lib/Core/Repositories/config_repository_query_part.dart',
      'lib/Core/Repositories/moderation_repository_library.dart',
      'lib/Core/Repositories/moderation_repository_facade_part.dart',
      'lib/Core/Repositories/notification_preferences_repository.dart',
      'lib/Core/Repositories/notification_preferences_repository_cache_part.dart',
      'lib/Core/Repositories/verified_account_repository.dart',
      'lib/Core/Repositories/verified_account_repository_cache_part.dart',
    ];
    final violations = <String>[];

    for (final path in checkedFiles) {
      final lines = await File(path).readAsLines();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (line.contains('AppFirestore.instance')) continue;
        if (line.contains('FirebaseFirestore.instance')) {
          violations.add('$path:${index + 1}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Config/preference/moderation repositories should use '
          'AppFirestore.',
    );
  });
}
