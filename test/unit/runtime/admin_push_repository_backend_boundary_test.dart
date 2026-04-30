import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AdminPushRepository uses AppFirestore boundary', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/admin_push_repository.dart',
      'lib/Core/Repositories/admin_push_repository_action_part.dart',
      'lib/Core/Repositories/admin_push_repository_query_part.dart',
      'lib/Core/Repositories/admin_push_repository_support_part.dart',
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
      reason: 'AdminPushRepository should access Firestore through '
          'AppFirestore.',
    );
  });
}
