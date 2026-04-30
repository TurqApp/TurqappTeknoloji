import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user repositories use AppFirestore boundary', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/user_repository.dart',
      'lib/Core/Repositories/user_repository_profile_part.dart',
      'lib/Core/Repositories/user_repository_query_part.dart',
      'lib/Core/Repositories/user_subdoc_repository.dart',
      'lib/Core/Repositories/user_subdoc_repository_runtime_part.dart',
      'lib/Core/Repositories/user_subcollection_repository.dart',
      'lib/Core/Repositories/user_subcollection_repository_query_part.dart',
      'lib/Core/Repositories/user_subcollection_repository_action_part.dart',
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
      reason: 'User repositories should access Firestore through AppFirestore.',
    );
  });
}
