import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Typesense cache services use local preference repository', () async {
    final checkedFiles = <String>[
      'lib/Core/Services/typesense_post_service.dart',
      'lib/Core/Services/typesense_post_service_cache_part.dart',
      'lib/Core/Services/typesense_market_service.dart',
      'lib/Core/Services/typesense_market_service_cache_part.dart',
      'lib/Core/Services/typesense_user_card_cache_service.dart',
      'lib/Core/Services/typesense_user_card_cache_service_cache_part.dart',
      'lib/Core/Services/typesense_education_service.dart',
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
      reason: 'Typesense cache services should use LocalPreferenceRepository.',
    );
  });
}
