import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('short profile and report opens stay behind navigation services',
      () async {
    final shortSource = await File(
      'lib/Modules/Short/short_content.dart',
    ).readAsString();
    final actionsSource = await File(
      'lib/Modules/Short/short_content_actions_part.dart',
    ).readAsString();
    final bodySource = await File(
      'lib/Modules/Short/short_content_body_part.dart',
    ).readAsString();
    final source = '$shortSource\n$actionsSource\n$bodySource';

    expect(source, contains('ProfileNavigationService'));
    expect(source, contains('ReportUserNavigationService'));
    expect(source, contains('openSocialProfile(model.userID)'));
    expect(source, contains('openSocialProfile(targetUid)'));
    expect(source, contains('openReportUser('));
    expect(source, contains('volumeOff(false)'));
    expect(source, contains('volumeOff(true)'));
    expect(source, isNot(contains('Get.to(() => SocialProfile')));
    expect(source, isNot(contains('Get.to(() => ReportUser')));
    expect(source, isNot(contains('Modules/SocialProfile/ReportUser')));
    expect(source, isNot(contains('../SocialProfile/social_profile.dart')));
  });
}
