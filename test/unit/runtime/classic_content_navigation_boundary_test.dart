import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ClassicContent profile and report opens stay behind services',
      () async {
    final checkedSources = <String, String>{
      'classic content':
          'lib/Modules/Agenda/ClassicContent/classic_content.dart',
      'header actions':
          'lib/Modules/Agenda/ClassicContent/classic_content_header_actions_part.dart',
      'header menu':
          'lib/Modules/Agenda/ClassicContent/classic_content_header_menu_part.dart',
      'quote':
          'lib/Modules/Agenda/ClassicContent/classic_content_quote_part.dart',
      'helpers':
          'lib/Modules/Agenda/ClassicContent/classic_content_helpers_part.dart',
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
    expect(source, contains('_restoreClassicFeedCenter()'));
    expect(source, isNot(contains('Get.to(() => SocialProfile')));
    expect(source, isNot(contains('Get.to(() => ReportUser')));
    expect(
      source,
      isNot(contains('Modules/SocialProfile/ReportUser/report_user.dart')),
    );
    expect(source, isNot(contains('../../SocialProfile/social_profile.dart')));
  });
}
