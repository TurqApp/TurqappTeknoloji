import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Social comments and photo shorts profile/report opens use services',
      () async {
    final checkedSources = <String, String>{
      'post comment': 'lib/Modules/Social/Comments/post_comment_content.dart',
      'photo short': 'lib/Modules/Social/PhotoShorts/photo_short_content.dart',
      'photo short body':
          'lib/Modules/Social/PhotoShorts/photo_short_content_body_part.dart',
    };

    final combinedSources = StringBuffer();
    for (final sourcePath in checkedSources.values) {
      combinedSources.writeln(await File(sourcePath).readAsString());
    }
    final source = combinedSources.toString();

    expect(source, contains('ProfileNavigationService'));
    expect(source, contains('ReportUserNavigationService'));
    expect(source, contains('openSocialProfile'));
    expect(source, contains('openReportUser('));
    expect(source, contains('StoryViewer('));
    expect(source, contains('widget.model.userID == _currentUserId'));
    expect(source, isNot(contains('Get.to(() => SocialProfile')));
    expect(source, isNot(contains('Get.to(SocialProfile')));
    expect(source, isNot(contains('Get.to(() => ReportUser')));
    expect(
      source,
      isNot(contains('Modules/SocialProfile/social_profile.dart')),
    );
    expect(
      source,
      isNot(contains('SocialProfile/ReportUser/report_user.dart')),
    );
  });
}
