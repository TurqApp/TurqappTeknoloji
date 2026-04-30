import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('education snapshot repositories use AppFirestore', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/optical_form_snapshot_repository.dart',
      'lib/Core/Repositories/practice_exam_snapshot_repository.dart',
      'lib/Core/Repositories/practice_exam_snapshot_repository_runtime_part.dart',
      'lib/Core/Repositories/test_snapshot_repository.dart',
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
      reason: 'Education snapshot repositories should access Firestore '
          'through AppFirestore.',
    );
  });
}
