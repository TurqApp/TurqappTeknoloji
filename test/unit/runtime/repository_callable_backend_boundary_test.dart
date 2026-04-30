import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository callable and report access use app backend boundaries',
      () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/explore_repository.dart',
      'lib/Core/Repositories/explore_repository_cache_part.dart',
      'lib/Core/Repositories/market_repository_library.dart',
      'lib/Core/Repositories/market_repository_action_part.dart',
      'lib/Core/Repositories/report_repository.dart',
      'lib/Core/Repositories/report_repository_data_part.dart',
      'lib/Core/Repositories/report_repository_facade_part.dart',
    ];
    final violations = <String>[];

    for (final path in checkedFiles) {
      final lines = await File(path).readAsLines();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (line.contains('AppFirestore.instance') ||
            line.contains('AppCloudFunctions.instance')) {
          continue;
        }
        if (line.contains('FirebaseFirestore.instance') ||
            line.contains('FirebaseFunctions.instance') ||
            line.contains('FirebaseFunctions.instanceFor')) {
          violations.add('$path:${index + 1}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Repository callable/report access should use '
          'AppFirestore/AppCloudFunctions.',
    );
  });
}
