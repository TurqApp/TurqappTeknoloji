import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user profile services use AppFirestore boundary', () async {
    final checkedFiles = <String>[
      'lib/Core/Services/user_profile_cache_service.dart',
      'lib/Core/Services/user_profile_cache_service_fetch_part.dart',
      'lib/Services/current_user_service.dart',
      'lib/Services/current_user_service_account_part.dart',
      'lib/Services/user_analytics_service.dart',
      'lib/Services/user_post_link_service.dart',
      'lib/Services/post_interaction_service.dart',
      'lib/Services/post_interaction_service_facade_part.dart',
    ];
    final violations = <String>[];

    for (final path in checkedFiles) {
      final source = await File(path).readAsString();
      if (source.contains('FirebaseFirestore.instance')) {
        violations.add(path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'User/profile services should use AppFirestore.',
    );
  });
}
