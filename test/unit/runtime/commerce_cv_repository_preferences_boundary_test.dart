import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('commerce and CV repositories use local preference repository',
      () async {
    final checkedFiles = <String>[
      'lib/Core/Repositories/market_repository_library.dart',
      'lib/Core/Repositories/market_repository_class_part.dart',
      'lib/Core/Repositories/market_repository_cache_part.dart',
      'lib/Core/Repositories/cv_repository.dart',
      'lib/Core/Repositories/cv_repository_cache_part.dart',
      'lib/Core/Repositories/cikmis_sorular_repository_parts.dart',
      'lib/Core/Repositories/cikmis_sorular_repository_base_part.dart',
      'lib/Core/Repositories/cikmis_sorular_repository_cache_part.dart',
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
      reason: 'Commerce/CV repositories should use LocalPreferenceRepository.',
    );
  });
}
