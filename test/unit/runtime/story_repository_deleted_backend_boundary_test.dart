import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StoryRepository deleted-story flow uses app backend boundaries',
      () async {
    final source = await File(
      'lib/Core/Repositories/story_repository_deleted_part.dart',
    ).readAsString();
    final violations = <String>[];
    final lines = source.split('\n');
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (line.contains('AppFirestore.instance') ||
          line.contains('AppFirebaseStorage.instance')) {
        continue;
      }
      if (line.contains('FirebaseFirestore.instance') ||
          line.contains('FirebaseStorage.instance')) {
        violations.add('story_repository_deleted_part.dart:${index + 1}');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'StoryRepository deleted-story flow should access backend '
          'singletons through app boundaries.',
    );
  });
}
