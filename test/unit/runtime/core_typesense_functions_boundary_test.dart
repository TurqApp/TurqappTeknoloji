import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Core Typesense services use AppCloudFunctions boundary', () async {
    final checkedFiles = <String>[
      'lib/Core/Services/typesense_education_service.dart',
      'lib/Core/Services/typesense_post_service.dart',
      'lib/Core/Services/typesense_user_service.dart',
      'lib/Core/Services/typesense_market_service.dart',
      'lib/Core/Services/typesense_education_admin_service.dart',
      'lib/Core/Services/typesense_market_admin_service.dart',
      'lib/Core/Services/short_link_service.dart',
      'lib/Core/Services/short_link_service_upsert_part.dart',
    ];
    final violations = <String>[];

    for (final path in checkedFiles) {
      final source = await File(path).readAsString();
      if (!source.contains('FirebaseFunctions.instance')) continue;
      violations.add(path);
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Core Typesense/short-link services should use AppCloudFunctions.',
    );
  });
}
