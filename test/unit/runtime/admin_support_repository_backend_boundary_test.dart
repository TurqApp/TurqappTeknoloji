import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin support and notification repositories use AppFirestore',
      () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/admin_approval_repository.dart',
      'lib/Core/Repositories/admin_approval_repository_facade_part.dart',
      'lib/Core/Repositories/admin_task_assignment_repository.dart',
      'lib/Core/Repositories/admin_task_assignment_repository_facade_part.dart',
      'lib/Core/Repositories/support_message_repository.dart',
      'lib/Core/Repositories/support_message_repository_facade_part.dart',
      'lib/Core/Repositories/notifications_repository.dart',
      'lib/Core/Repositories/conversation_repository.dart',
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
      reason: 'Admin/support/notification repositories should use '
          'AppFirestore.',
    );
  });
}
