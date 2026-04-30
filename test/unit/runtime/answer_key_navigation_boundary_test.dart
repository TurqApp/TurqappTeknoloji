import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('answer key booklet preview opens stay behind navigation service',
      () async {
    final serviceSource = await File(
      'lib/Core/Services/answer_key_navigation_service.dart',
    ).readAsString();
    final checkedSources = <String, String>{
      'answer key content': 'lib/Modules/Education/AnswerKey/AnswerKeyContent/'
          'answer_key_content_controller_actions_part.dart',
      'search answer key': 'lib/Modules/Education/AnswerKey/SearchAnswerKey/'
          'search_answer_key_controller_runtime_part.dart',
      'category answer key':
          'lib/Modules/Education/AnswerKey/CategoryBasedAnswerKey/'
              'category_based_answer_key.dart',
    };

    expect(serviceSource, contains('openBookletPreview'));
    expect(serviceSource, contains('BookletPreview(model: model)'));

    for (final entry in checkedSources.entries) {
      final source = await File(entry.value).readAsString();

      expect(
        source,
        contains('openBookletPreview('),
        reason: '${entry.key} should delegate booklet preview opening.',
      );
      expect(
        source,
        isNot(contains('Get.to(() => BookletPreview')),
        reason: '${entry.key} should not open BookletPreview directly.',
      );
    }
  });

  test('answer key entry opens stay behind navigation service', () async {
    final serviceSource = await File(
      'lib/Core/Services/answer_key_navigation_service.dart',
    ).readAsString();
    final answerKeyShellSource = await File(
      'lib/Modules/Education/AnswerKey/answer_key_shell_content_part.dart',
    ).readAsString();
    final answerKeySectionsSource = await File(
      'lib/Modules/Education/AnswerKey/answer_key_sections_part.dart',
    ).readAsString();
    final educationSource = await File(
      'lib/Modules/Education/education_view_actions_part.dart',
    ).readAsString();
    final previewControllerSource = await File(
      'lib/Modules/Education/AnswerKey/BookletPreview/'
      'booklet_preview_controller_runtime_part.dart',
    ).readAsString();

    for (final method in <String>[
      'openSearchAnswerKey',
      'openCategoryAnswerKey',
      'openPublishedAnswerKeys',
      'openSavedOpticalForms',
      'openMyBookletResults',
      'openCreateAnswerKey',
      'openOpticalFormEntry',
      'openBookletAnswer',
    ]) {
      expect(serviceSource, contains(method));
    }

    expect(answerKeyShellSource, contains('openPublishedAnswerKeys()'));
    expect(answerKeyShellSource, contains('openSavedOpticalForms()'));
    expect(answerKeyShellSource, contains('openMyBookletResults()'));
    expect(answerKeyShellSource, contains('openCreateAnswerKey('));
    expect(answerKeyShellSource, contains('openOpticalFormEntry()'));
    expect(answerKeySectionsSource, contains('openSearchAnswerKey()'));
    expect(answerKeySectionsSource, contains('openCategoryAnswerKey('));
    expect(educationSource, contains('openSearchAnswerKey()'));
    expect(educationSource, contains('openSavedOpticalForms()'));
    expect(educationSource, contains('openOpticalFormEntry()'));
    expect(educationSource, contains('openCreateAnswerKey('));
    expect(educationSource, contains('openMyBookletResults()'));
    expect(educationSource, contains('openPublishedAnswerKeys()'));
    expect(previewControllerSource, contains('openBookletAnswer('));
  });

  test('feature code does not open answer key routes directly', () async {
    const approvedFiles = <String>{
      'lib/Core/Services/answer_key_navigation_service.dart',
    };
    final directRouteTokens = <String>[
      'BookletPreview(model:',
      'BookletAnswer(model:',
      '=> SearchAnswerKey(',
      'Get.to(() => SearchAnswerKey',
      '=> const SearchAnswerKey(',
      'Get.to(() => const SearchAnswerKey',
      '=> CategoryBasedAnswerKey(',
      'Get.to(() => CategoryBasedAnswerKey',
      '=> OpticsAndBooksPublished(',
      'Get.to(OpticsAndBooksPublished',
      '=> const OpticsAndBooksPublished(',
      '=> SavedOpticalForms(',
      'Get.to(SavedOpticalForms',
      '=> const SavedOpticalForms(',
      '=> MyBookletResults(',
      'Get.to(MyBookletResults',
      '=> const MyBookletResults(',
      '=> AnswerKeyCreatingOption(',
      'Get.to(AnswerKeyCreatingOption',
      '=> OpticalFormEntry(',
      'Get.to(OpticalFormEntry',
      '=> const OpticalFormEntry(',
    ];
    final violations = <String>[];

    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (approvedFiles.contains(normalizedPath)) continue;

      final source = await file.readAsString();
      if (!directRouteTokens.any(source.contains)) continue;
      violations.add(normalizedPath);
    }

    expect(
      violations,
      isEmpty,
      reason: 'Answer key route creation should stay behind '
          'AnswerKeyNavigationService.',
    );
  });
}
