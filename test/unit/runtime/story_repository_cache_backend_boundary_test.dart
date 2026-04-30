import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StoryRepository foundation and cache use app backend boundaries',
      () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/story_repository.dart',
      'lib/Core/Repositories/story_repository_foundation_part.dart',
      'lib/Core/Repositories/story_repository_cache_part.dart',
    ];
    final violations = <String>[];

    for (final path in checkedFiles) {
      final lines = await File(path).readAsLines();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (line.contains('AppFirestore.instance') ||
            line.contains('AppFirebaseStorage.instance')) {
          continue;
        }
        if (line.contains('FirebaseFirestore.instance') ||
            line.contains('FirebaseStorage.instance')) {
          violations.add('$path:${index + 1}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'StoryRepository foundation/cache should access backend '
          'singletons through app boundaries.',
    );
  });
}
