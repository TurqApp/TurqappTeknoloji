import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Scholarships listing controller uses local preference repository',
      () async {
    final checkedFiles = <String>[
      'lib/Modules/Education/Scholarships/scholarships_controller.dart',
      'lib/Modules/Education/Scholarships/scholarships_controller_data_part.dart',
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
      reason: 'Scholarships listing controller should use '
          'LocalPreferenceRepository for prefs.',
    );
  });
}
