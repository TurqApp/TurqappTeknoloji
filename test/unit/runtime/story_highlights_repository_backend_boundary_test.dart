import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StoryHighlightsRepository uses AppFirestore', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/story_highlights_repository.dart',
      'lib/Core/Repositories/story_highlights_repository_action_part.dart',
      'lib/Core/Repositories/story_highlights_repository_query_part.dart',
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
      reason: 'StoryHighlightsRepository should access Firestore through '
          'AppFirestore.',
    );
  });
}
