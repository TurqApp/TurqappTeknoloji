import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('education repositories use local preference repository', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/practice_exam_repository.dart',
      'lib/Core/Repositories/practice_exam_repository_lifecycle_part.dart',
      'lib/Core/Repositories/practice_exam_repository_action_part.dart',
      'lib/Core/Repositories/practice_exam_repository_cache_part.dart',
      'lib/Core/Repositories/test_repository_parts.dart',
      'lib/Core/Repositories/test_repository_facade_part.dart',
      'lib/Core/Repositories/test_repository_cache_part.dart',
      'lib/Core/Repositories/optical_form_repository.dart',
      'lib/Core/Repositories/optical_form_repository_base_part.dart',
      'lib/Core/Repositories/optical_form_repository_action_part.dart',
      'lib/Core/Repositories/optical_form_repository_cache_part.dart',
      'lib/Core/Repositories/booklet_repository.dart',
      'lib/Core/Repositories/booklet_repository_action_part.dart',
      'lib/Core/Repositories/booklet_repository_cache_part.dart',
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
      reason: 'Education repositories should use LocalPreferenceRepository.',
    );
  });
}
