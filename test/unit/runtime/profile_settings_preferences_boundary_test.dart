import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Profile settings use local preference repository', () async {
    final checkedFiles = <String>[
      'lib/Modules/Profile/Settings/settings_controller.dart',
      'lib/Modules/Profile/Settings/settings_controller_runtime_part.dart',
      'lib/Modules/Profile/Settings/permissions_view.dart',
      'lib/Modules/Profile/Settings/permissions_view_quota_part.dart',
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
      reason: 'Profile settings should use LocalPreferenceRepository.',
    );
  });
}
