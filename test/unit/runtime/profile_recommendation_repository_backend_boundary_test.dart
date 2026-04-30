import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile and recommendation repositories use AppFirestore', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/profile_repository_library.dart',
      'lib/Core/Repositories/profile_repository_fields_part.dart',
      'lib/Core/Repositories/profile_stats_repository.dart',
      'lib/Core/Repositories/profile_stats_repository_metrics_part.dart',
      'lib/Core/Repositories/recommended_users_repository.dart',
      'lib/Core/Repositories/recommended_users_repository_runtime_part.dart',
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
      reason: 'Profile and recommendation repositories should use '
          'AppFirestore.',
    );
  });
}
