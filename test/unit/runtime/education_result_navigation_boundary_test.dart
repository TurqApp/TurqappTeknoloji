import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('education result preview opens stay behind navigation service',
      () async {
    final serviceSource = await File(
      'lib/Core/Services/education_result_navigation_service.dart',
    ).readAsString();
    final checkedSources = <String, String>{
      'booklet result': 'lib/Modules/Education/AnswerKey/BookletResultContent/'
          'booklet_result_content.dart',
      'test past result': 'lib/Modules/Education/Tests/TestPastResultContent/'
          'test_past_result_content_card_part.dart',
      'practice exam result':
          'lib/Modules/Education/PracticeExams/DenemeGecmisSonucContent/'
              'deneme_gecmis_sonuc_content.dart',
    };

    expect(serviceSource, contains('openBookletResultPreview'));
    expect(serviceSource, contains('openTestPastResultPreview'));
    expect(serviceSource, contains('openPracticeExamResultPreview'));
    expect(serviceSource, contains('BookletResultPreview(model: model)'));
    expect(serviceSource, contains('MyPastTestResultsPreview(model: model)'));
    expect(serviceSource, contains('SinavSonuclariPreview(model: model)'));

    for (final entry in checkedSources.entries) {
      final source = await File(entry.value).readAsString();

      expect(
        source,
        contains('EducationResultNavigationService()'),
        reason: '${entry.key} should delegate result preview opening.',
      );
      expect(
        source,
        isNot(contains('Get.to(() => BookletResultPreview')),
        reason: '${entry.key} should not open result preview directly.',
      );
      expect(
        source,
        isNot(contains('Get.to(() => MyPastTestResultsPreview')),
        reason: '${entry.key} should not open result preview directly.',
      );
      expect(
        source,
        isNot(contains('Get.to(() => SinavSonuclariPreview')),
        reason: '${entry.key} should not open result preview directly.',
      );
    }
  });

  test('feature code does not open education result previews directly',
      () async {
    const approvedFiles = <String>{
      'lib/Core/Services/education_result_navigation_service.dart',
    };
    final previewTokens = <String>{
      'BookletResultPreview(model:',
      'MyPastTestResultsPreview(model:',
      'SinavSonuclariPreview(model:',
    };
    final violations = <String>[];

    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (approvedFiles.contains(normalizedPath)) continue;

      final source = await file.readAsString();
      if (!previewTokens.any(source.contains)) continue;
      violations.add(normalizedPath);
    }

    expect(
      violations,
      isEmpty,
      reason: 'Education result preview route creation should stay behind '
          'EducationResultNavigationService.',
    );
  });
}
