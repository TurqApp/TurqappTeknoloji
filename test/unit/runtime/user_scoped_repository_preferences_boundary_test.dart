import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user-scoped repositories use local preference repository', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/user_subdoc_repository.dart',
      'lib/Core/Repositories/user_subdoc_repository_runtime_part.dart',
      'lib/Core/Repositories/user_subdoc_repository_cache_part.dart',
      'lib/Core/Repositories/user_subcollection_repository.dart',
      'lib/Core/Repositories/user_subcollection_repository_storage_part.dart',
      'lib/Core/Repositories/social_media_links_repository.dart',
      'lib/Core/Repositories/social_media_links_repository_base_part.dart',
      'lib/Core/Repositories/social_media_links_repository_storage_part.dart',
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
      reason: 'User-scoped repositories should use LocalPreferenceRepository.',
    );
  });
}
