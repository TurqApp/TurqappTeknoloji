import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Profile settings and social profile report opens use services',
      () async {
    final checkedSources = <String, String>{
      'social profile': 'lib/Modules/SocialProfile/social_profile.dart',
      'social profile header':
          'lib/Modules/SocialProfile/social_profile_header_part.dart',
      'badge admin': 'lib/Modules/Profile/Settings/badge_admin_view.dart',
      'badge admin applications':
          'lib/Modules/Profile/Settings/badge_admin_view_applications_part.dart',
      'support admin': 'lib/Modules/Profile/Settings/support_admin_view.dart',
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
    expect(source, contains('controller.resumeCenteredPost()'));
    expect(source, contains('controller.getUserData()'));
    expect(source, isNot(contains('Get.to(() => SocialProfile')));
    expect(source, isNot(contains('Get.to(SocialProfile')));
    expect(source, isNot(contains('Get.to(() => ReportUser')));
    expect(
      source,
      isNot(contains('Modules/SocialProfile/ReportUser/report_user.dart')),
    );
  });
}
