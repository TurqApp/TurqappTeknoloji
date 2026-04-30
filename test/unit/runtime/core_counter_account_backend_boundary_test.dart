import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counter and account limit services use AppFirestore boundary',
      () async {
    final checkedFiles = <String>[
      'lib/Services/post_count_manager.dart',
      'lib/Services/post_count_manager_actions_part.dart',
      'lib/Services/phone_account_limiter.dart',
    ];
    final violations = <String>[];

    for (final path in checkedFiles) {
      final source = await File(path).readAsString();
      if (source.split('\n').any((line) {
        if (line.contains('AppFirestore.instance')) return false;
        return line.contains('FirebaseFirestore.instance');
      })) {
        violations.add(path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Counter and account limit services should access Firestore '
          'through AppFirestore.',
    );
  });
}
