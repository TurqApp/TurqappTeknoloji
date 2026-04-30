import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile follower and notification avatar opens stay behind service',
      () async {
    final checkedSources = <String, String>{
      'follower content':
          'lib/Modules/Profile/FollowingFollowers/follower_content.dart',
      'follower actions':
          'lib/Modules/Profile/FollowingFollowers/follower_content_view_part.dart',
      'notification content':
          'lib/Modules/InAppNotifications/notification_content.dart',
      'notification actions':
          'lib/Modules/InAppNotifications/notification_content_actions_part.dart',
    };

    final combinedSources = StringBuffer();
    for (final sourcePath in checkedSources.values) {
      combinedSources.writeln(await File(sourcePath).readAsString());
    }
    final source = combinedSources.toString();

    expect(source, contains('ProfileNavigationService'));
    expect(source, contains('openSocialProfile'));
    expect(source, contains('controller.followControl(widget.userID)'));
    expect(source, contains('onCardTap'));
    expect(source, isNot(contains('Get.to(() => SocialProfile')));
    expect(
      source,
      isNot(contains('Modules/SocialProfile/social_profile.dart')),
    );
  });
}
