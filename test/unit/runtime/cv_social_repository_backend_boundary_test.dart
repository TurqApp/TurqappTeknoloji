import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CV and social media repositories use AppFirestore', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/cv_repository.dart',
      'lib/Core/Repositories/cv_repository_cache_part.dart',
      'lib/Core/Repositories/social_media_links_repository.dart',
      'lib/Core/Repositories/social_media_links_repository_query_part.dart',
      'lib/Core/Repositories/social_media_links_repository_action_part.dart',
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
      reason: 'CV and social media repositories should use AppFirestore.',
    );
  });
}
