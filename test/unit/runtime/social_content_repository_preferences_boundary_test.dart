import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('social content repositories use local preference repository', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/story_repository.dart',
      'lib/Core/Repositories/story_repository_foundation_part.dart',
      'lib/Core/Repositories/story_highlights_repository.dart',
      'lib/Core/Repositories/story_highlights_repository_lifecycle_part.dart',
      'lib/Core/Repositories/story_highlights_repository_cache_part.dart',
      'lib/Core/Repositories/story_highlights_repository_action_part.dart',
      'lib/Core/Repositories/profile_repository_library.dart',
      'lib/Core/Repositories/profile_repository_cache_part.dart',
      'lib/Core/Repositories/post_repository.dart',
      'lib/Core/Repositories/post_repository_query_part.dart',
      'lib/Core/Repositories/feed_manifest_repository.dart',
      'lib/Core/Repositories/explore_repository.dart',
      'lib/Core/Repositories/explore_repository_cache_part.dart',
      'lib/Core/Repositories/recommended_users_repository.dart',
      'lib/Core/Repositories/recommended_users_repository_runtime_part.dart',
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
      reason:
          'Social content repositories should use LocalPreferenceRepository.',
    );
  });
}
