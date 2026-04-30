import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Core Ads services use backend boundary services', () async {
    final checkedFiles = <String>[
      'lib/Core/Services/Ads/ads_feature_flags_service.dart',
      'lib/Core/Services/Ads/ads_feature_flags_service_base_part.dart',
      'lib/Core/Services/Ads/ads_feature_flags_service_runtime_part.dart',
      'lib/Core/Services/Ads/ads_analytics_service.dart',
      'lib/Core/Services/Ads/ads_delivery_service.dart',
      'lib/Core/Services/Ads/ads_repository_service.dart',
      'lib/Core/Services/Ads/turqapp_suggestion_config_service.dart',
    ];
    final violations = <String>[];

    for (final path in checkedFiles) {
      final source = await File(path).readAsString();
      final hasDirectBackendSingleton = source.split('\n').any((line) {
        if (line.contains('AppFirestore.instance') ||
            line.contains('AppCloudFunctions.instance') ||
            line.contains('AppFirebaseStorage.instance')) {
          return false;
        }
        return line.contains('FirebaseFirestore.instance') ||
            line.contains('FirebaseFunctions.instance') ||
            line.contains('FirebaseFunctions.instanceFor') ||
            line.contains('FirebaseStorage.instance');
      });
      if (hasDirectBackendSingleton) {
        violations.add(path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Core Ads services should access backend singletons through '
          'AppFirestore/AppCloudFunctions/AppFirebaseStorage.',
    );
  });
}
