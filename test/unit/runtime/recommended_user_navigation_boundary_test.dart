import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recommended user profile opens stay behind ProfileNavigationService',
      () async {
    final source = await File(
      'lib/Modules/RecommendedUserList/RecommendedUserContent/'
      'recommended_user_content.dart',
    ).readAsString();

    expect(source, contains('ProfileNavigationService'));
    expect(source, contains('openSocialProfile(controller.userID)'));
    expect(source, contains('controller.getTakipStatus()'));
    expect(source, isNot(contains('Get.to(() => SocialProfile')));
    expect(
      source,
      isNot(contains('Modules/SocialProfile/social_profile.dart')),
    );
  });
}
