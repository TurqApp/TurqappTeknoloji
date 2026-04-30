import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StoryInteractionOptimizer uses AppFirestore boundary', () async {
    final checkedFiles = <String>[
      'lib/Services/story_interaction_optimizer_library.dart',
      'lib/Services/story_interaction_optimizer_runtime_part.dart',
    ];
    final violations = <String>[];

    for (final path in checkedFiles) {
      final source = await File(path).readAsString();
      if (source.split('\n').any((line) {
        if (line.contains('AppFirestore.instance')) return false;
        return line.contains('FirebaseFirestore.instance');
      })) {
        violations.add(path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Story interaction writes should access Firestore through '
          'AppFirestore.',
    );
  });
}
