import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('practice exam preview opens stay behind navigation service', () async {
    final serviceSource = await File(
      'lib/Core/Services/practice_exam_navigation_service.dart',
    ).readAsString();
    final gridSource = await File(
      'lib/Modules/Education/PracticeExams/DenemeGrid/'
      'deneme_grid_actions_part.dart',
    ).readAsString();
    final ctaSource = await File(
      'lib/Core/Services/education_feed_cta_navigation_service.dart',
    ).readAsString();

    expect(serviceSource, contains('openPreview'));
    expect(serviceSource, contains('DenemeSinaviPreview(model: model)'));
    expect(
      gridSource,
      contains('PracticeExamNavigationService().openPreview(model)'),
    );
    expect(
      ctaSource,
      contains('PracticeExamNavigationService().openPreview(model)'),
    );
    expect(gridSource, contains('Get.back();'));
    expect(gridSource, isNot(contains('Get.to(() => DenemeSinaviPreview')));
    expect(ctaSource, isNot(contains('Get.to(() => DenemeSinaviPreview')));
  });

  test('practice exam entry opens stay behind navigation service', () async {
    final serviceSource = await File(
      'lib/Core/Services/practice_exam_navigation_service.dart',
    ).readAsString();
    final denemeSource = await File(
      'lib/Modules/Education/PracticeExams/deneme_sinavlari_actions_part.dart',
    ).readAsString();
    final sectionsSource = await File(
      'lib/Modules/Education/PracticeExams/deneme_sinavlari_sections_part.dart',
    ).readAsString();
    final shellSource = await File(
      'lib/Modules/Education/PracticeExams/deneme_sinavlari.dart',
    ).readAsString();
    final gridSource = await File(
      'lib/Modules/Education/PracticeExams/DenemeGrid/'
      'deneme_grid_actions_part.dart',
    ).readAsString();
    final educationSource = await File(
      'lib/Modules/Education/education_view_actions_part.dart',
    ).readAsString();

    for (final method in <String>[
      'openSearchPracticeExams',
      'openCreatePracticeExam',
      'openMyPracticeExamResults',
      'openMyPracticeExams',
      'openSavedPracticeExams',
    ]) {
      expect(serviceSource, contains(method));
    }

    expect(denemeSource, contains('openCreatePracticeExam()'));
    expect(denemeSource, contains('openMyPracticeExamResults()'));
    expect(denemeSource, contains('openMyPracticeExams()'));
    expect(denemeSource, contains('openSavedPracticeExams()'));
    expect(denemeSource, contains('openSearchPracticeExams()'));
    expect(sectionsSource, contains('openSearchPracticeExams()'));
    expect(shellSource, contains('openSearchPracticeExams()'));
    expect(gridSource, contains('openCreatePracticeExam(model: model)'));
    expect(educationSource, contains('openSearchPracticeExams()'));
    expect(educationSource, contains('openCreatePracticeExam()'));
    expect(educationSource, contains('openMyPracticeExamResults()'));
    expect(educationSource, contains('openMyPracticeExams()'));
    expect(educationSource, contains('openSavedPracticeExams()'));
  });

  test('feature code does not open practice exam routes directly', () async {
    const approvedFiles = <String>{
      'lib/Core/Services/practice_exam_navigation_service.dart',
    };
    final directRouteTokens = <String>[
      'DenemeSinaviPreview(model:',
      '=> SearchDeneme(',
      'Get.to(() => SearchDeneme',
      '=> SinavHazirla(',
      'Get.to(() => SinavHazirla',
      '=> SinavSonuclarim(',
      'Get.to(() => SinavSonuclarim',
      '=> const MyPracticeExams(',
      'Get.to(() => const MyPracticeExams',
      '=> const SavedPracticeExams(',
      'Get.to(() => const SavedPracticeExams',
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
      reason: 'Practice exam route creation should stay behind '
          'PracticeExamNavigationService.',
    );
  });
}
