import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StoryRepository engagement flow uses AppFirestore', () async {
    final source = await File(
      'lib/Core/Repositories/story_repository_engagement_part.dart',
    ).readAsString();
    final violations = <String>[];
    final lines = source.split('\n');
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (line.contains('AppFirestore.instance')) continue;
      if (line.contains('FirebaseFirestore.instance')) {
        violations.add('story_repository_engagement_part.dart:${index + 1}');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'StoryRepository engagement flow should access Firestore through '
          'AppFirestore.',
    );
  });
}
