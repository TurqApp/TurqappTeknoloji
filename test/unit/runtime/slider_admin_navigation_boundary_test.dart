import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('education slider admin opens stay behind navigation service', () async {
    final serviceSource = await File(
      'lib/Core/Services/slider_admin_navigation_service.dart',
    ).readAsString();
    final checkedSources = <String, String>{
      'education actions':
          'lib/Modules/Education/education_view_actions_part.dart',
      'answer key shell':
          'lib/Modules/Education/AnswerKey/answer_key_shell_content_part.dart',
      'practice exam actions':
          'lib/Modules/Education/PracticeExams/deneme_sinavlari_actions_part.dart',
      'tutoring shell':
          'lib/Modules/Education/Tutoring/tutoring_view_shell_content_part.dart',
      'past questions':
          'lib/Modules/Education/CikmisSorular/cikmis_sorular.dart',
    };

    expect(serviceSource, contains('openSliderAdmin'));
    expect(serviceSource, contains('SliderAdminView('));

    final combinedSources = StringBuffer();
    for (final entry in checkedSources.entries) {
      final source = await File(entry.value).readAsString();
      combinedSources.writeln(source);
      expect(
        source,
        contains('openSliderAdmin('),
        reason: '${entry.key} should delegate slider admin navigation.',
      );
    }

    expect(
      combinedSources.toString(),
      isNot(contains('SliderAdminView(')),
    );
  });
}
