import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('education report user opens stay behind navigation service', () async {
    final serviceSource = await File(
      'lib/Core/Services/report_user_navigation_service.dart',
    ).readAsString();
    final checkedSources = <String, String>{
      'scholarship detail':
          'lib/Modules/Education/Scholarships/ScholarshipDetail/'
              'scholarship_detail_view_actions_part.dart',
      'booklet preview': 'lib/Modules/Education/AnswerKey/BookletPreview/'
          'booklet_preview_widgets_part.dart',
      'practice exam preview':
          'lib/Modules/Education/PracticeExams/DenemeSinaviPreview/'
              'deneme_sinavi_preview.dart',
      'tutoring detail': 'lib/Modules/Education/Tutoring/TutoringDetail/'
          'tutoring_detail_sections_part.dart',
    };

    expect(serviceSource, contains('openReportUser'));
    expect(serviceSource, contains('ReportUser('));
    expect(serviceSource, contains("commentId = ''"));

    final combinedSources = StringBuffer();
    for (final entry in checkedSources.entries) {
      final source = await File(entry.value).readAsString();
      combinedSources.writeln(source);
      expect(
        source,
        contains('openReportUser('),
        reason: '${entry.key} should delegate report user navigation.',
      );
    }

    expect(
      combinedSources.toString(),
      isNot(contains('() => ReportUser(')),
    );
    expect(
      combinedSources.toString(),
      isNot(contains('Get.to(ReportUser(')),
    );
  });
}
