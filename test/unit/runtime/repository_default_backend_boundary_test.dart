import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository default backend dependencies use app boundaries', () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/antreman_repository.dart',
      'lib/Core/Repositories/booklet_repository.dart',
      'lib/Core/Repositories/booklet_repository_cache_part.dart',
      'lib/Core/Repositories/cikmis_sorular_repository_parts.dart',
      'lib/Core/Repositories/cikmis_sorular_repository_base_part.dart',
      'lib/Core/Repositories/explore_repository.dart',
      'lib/Core/Repositories/feed_manifest_repository.dart',
      'lib/Core/Repositories/job_repository.dart',
      'lib/Core/Repositories/job_repository_class_part.dart',
      'lib/Core/Repositories/market_repository_library.dart',
      'lib/Core/Repositories/market_repository_fields_part.dart',
      'lib/Core/Repositories/notify_lookup_repository_library.dart',
      'lib/Core/Repositories/notify_lookup_repository_base_part.dart',
      'lib/Core/Repositories/optical_form_repository.dart',
      'lib/Core/Repositories/optical_form_repository_base_part.dart',
      'lib/Core/Repositories/post_repository.dart',
      'lib/Core/Repositories/post_repository_support_part.dart',
      'lib/Core/Repositories/practice_exam_repository.dart',
      'lib/Core/Repositories/practice_exam_repository_fields_part.dart',
      'lib/Core/Repositories/profile_manifest_repository.dart',
      'lib/Core/Repositories/short_manifest_repository.dart',
      'lib/Core/Repositories/short_repository.dart',
      'lib/Core/Repositories/short_repository_class_part.dart',
      'lib/Core/Repositories/slider_repository_library.dart',
      'lib/Core/Repositories/slider_repository_base_part.dart',
      'lib/Core/Repositories/test_repository_parts.dart',
      'lib/Core/Repositories/test_repository_facade_part.dart',
      'lib/Core/Repositories/tutoring_repository.dart',
      'lib/Core/Repositories/tutoring_repository_base_part.dart',
      'lib/Core/Repositories/username_lookup_repository.dart',
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
      reason: 'Repository default backend dependencies should use '
          'AppFirestore/AppFirebaseStorage.',
    );
  });
}
