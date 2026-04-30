import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Antreman repository uses local preference repository', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/antreman_repository.dart',
      'lib/Core/Repositories/antreman_repository_query_part.dart',
      'lib/Core/Repositories/antreman_repository_action_part.dart',
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
      reason: 'Antreman repository should use LocalPreferenceRepository.',
    );
  });
}
