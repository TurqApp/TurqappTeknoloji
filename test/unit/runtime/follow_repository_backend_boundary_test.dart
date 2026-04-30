import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FollowRepository uses AppFirestore boundary', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/follow_repository.dart',
      'lib/Core/Repositories/follow_repository_action_part.dart',
      'lib/Core/Repositories/follow_repository_query_part.dart',
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
      reason: 'FollowRepository should access Firestore through AppFirestore.',
    );
  });
}
