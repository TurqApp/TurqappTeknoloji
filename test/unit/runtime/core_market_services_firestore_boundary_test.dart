import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Core market share services use AppFirestore boundary', () async {
    final checkedFiles = <String>[
      'lib/Core/Services/market_saved_store.dart',
      'lib/Core/Services/market_offer_service.dart',
      'lib/Core/Services/market_review_service.dart',
      'lib/Core/Services/market_contact_service.dart',
      'lib/Core/Services/market_feed_post_share_service.dart',
      'lib/Core/Services/education_feed_post_share_service.dart',
      'lib/Core/Services/education_feed_post_share_service_publish_part.dart',
    ];
    final violations = <String>[];

    for (final path in checkedFiles) {
      final source = await File(path).readAsString();
      if (!source.contains('FirebaseFirestore.instance')) continue;
      violations.add(path);
    }

    expect(
      violations,
      isEmpty,
      reason: 'Core market/feed services should use AppFirestore.',
    );
  });
}
