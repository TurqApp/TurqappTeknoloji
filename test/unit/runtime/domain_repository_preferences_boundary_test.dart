import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('domain repositories use local preference repository', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/scholarship_repository.dart',
      'lib/Core/Repositories/scholarship_repository_facade_part.dart',
      'lib/Core/Repositories/scholarship_repository_cache_part.dart',
      'lib/Core/Repositories/tutoring_repository.dart',
      'lib/Core/Repositories/tutoring_repository_cache_part.dart',
      'lib/Core/Repositories/job_repository.dart',
      'lib/Core/Repositories/job_repository_class_part.dart',
      'lib/Core/Repositories/job_repository_cache_part.dart',
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
      reason: 'Domain repositories should use LocalPreferenceRepository.',
    );
  });
}
