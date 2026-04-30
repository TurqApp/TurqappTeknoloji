import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('snapshot repositories use AppFirestore for Firestore fallbacks',
      () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/job_home_snapshot_repository.dart',
      'lib/Core/Repositories/job_home_snapshot_repository_data_part.dart',
      'lib/Core/Repositories/market_snapshot_repository.dart',
      'lib/Core/Repositories/market_snapshot_repository_data_part.dart',
      'lib/Core/Repositories/tutoring_snapshot_repository.dart',
      'lib/Core/Repositories/tutoring_snapshot_repository_pipeline_part.dart',
      'lib/Core/Repositories/answer_key_snapshot_repository.dart',
      'lib/Core/Repositories/answer_key_snapshot_repository_support_part.dart',
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
      reason: 'Snapshot repository Firestore fallbacks should use '
          'AppFirestore.',
    );
  });
}
