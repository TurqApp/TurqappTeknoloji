import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Core labels, QR, and Explore user opens use profile service', () async {
    final checkedSources = <String, String>{
      'profile service': 'lib/Core/Services/profile_navigation_service.dart',
      'qr scanner': 'lib/Core/Helpers/QRCode/qr_scanner_view.dart',
      'shared post label': 'lib/Core/Widgets/shared_post_label.dart',
      'search user content':
          'lib/Modules/Explore/SearchedUser/search_user_content.dart',
      'search user controller':
          'lib/Modules/Explore/SearchedUser/search_user_content_controller.dart',
      'search user controller runtime':
          'lib/Modules/Explore/SearchedUser/search_user_content_controller_runtime_part.dart',
    };

    final combinedSources = StringBuffer();
    final featureSources = StringBuffer();
    for (final entry in checkedSources.entries) {
      final source = await File(entry.value).readAsString();
      combinedSources.writeln(source);
      if (entry.key != 'profile service') {
        featureSources.writeln(source);
      }
    }
    final source = combinedSources.toString();
    final featureSource = featureSources.toString();

    expect(source, contains('ProfileNavigationService'));
    expect(source, contains('openSocialProfile'));
    expect(source, contains('preventDuplicates: preventDuplicates'));
    expect(source, contains('preventDuplicates: false'));
    expect(source, contains('suspendExplorePreview()'));
    expect(source, contains('resumeExplorePreview()'));
    expect(featureSource, isNot(contains('Get.to(() => SocialProfile')));
    expect(featureSource, isNot(contains('Get.to(SocialProfile')));
    expect(
      featureSource,
      isNot(contains('Modules/SocialProfile/social_profile.dart')),
    );
  });
}
