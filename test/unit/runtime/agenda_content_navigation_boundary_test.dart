import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AgendaContent profile and report opens stay behind services', () async {
    final checkedSources = <String, String>{
      'agenda content': 'lib/Modules/Agenda/AgendaContent/agenda_content.dart',
      'body': 'lib/Modules/Agenda/AgendaContent/agenda_content_body_part.dart',
      'header actions':
          'lib/Modules/Agenda/AgendaContent/agenda_content_header_actions_part.dart',
      'header navigation':
          'lib/Modules/Agenda/AgendaContent/agenda_content_header_navigation_part.dart',
      'header menu':
          'lib/Modules/Agenda/AgendaContent/agenda_content_header_menu_part.dart',
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
    expect(source, contains('_restoreAgendaFeedCenter()'));
    expect(source, isNot(contains('Get.to(() => SocialProfile')));
    expect(source, isNot(contains('Get.to(SocialProfile')));
    expect(source, isNot(contains('Get.to(() => ReportUser')));
    expect(
      source,
      isNot(contains('Modules/SocialProfile/ReportUser/report_user.dart')),
    );
    expect(source, isNot(contains('../../SocialProfile/social_profile.dart')));
  });
}
