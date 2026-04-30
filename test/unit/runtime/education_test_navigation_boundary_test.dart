import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test solve opens stay behind navigation service', () async {
    final serviceSource = await File(
      'lib/Core/Services/education_test_navigation_service.dart',
    ).readAsString();
    final checkedSources = <String, String>{
      'tests grid': 'lib/Modules/Education/Tests/TestsGrid/'
          'tests_grid_controller_actions_part.dart',
      'test entry': 'lib/Modules/Education/Tests/TestEntry/'
          'test_entry_controller_runtime_part.dart',
    };

    expect(serviceSource, contains('openSolveTest'));
    expect(serviceSource, contains('SolveTest(testID: testID'));

    for (final entry in checkedSources.entries) {
      final source = await File(entry.value).readAsString();

      expect(
        source,
        contains('openSolveTest('),
        reason: '${entry.key} should delegate solve navigation.',
      );
      expect(
        source,
        isNot(contains('Get.to(() => SolveTest')),
        reason: '${entry.key} should not open SolveTest directly.',
      );
    }

    final gridSource = await File(
      checkedSources['tests grid']!,
    ).readAsString();
    expect(gridSource, contains('Get.back();'));
  });

  test('test module entry opens stay behind navigation service', () async {
    final serviceSource = await File(
      'lib/Core/Services/education_test_navigation_service.dart',
    ).readAsString();
    final checkedSources = <String, String>{
      'tests shell':
          'lib/Modules/Education/Tests/tests_shell_content_part.dart',
      'tests search': 'lib/Modules/Education/Tests/tests_sections_part.dart',
      'my tests': 'lib/Modules/Education/Tests/MyTests/my_tests.dart',
      'tests grid': 'lib/Modules/Education/Tests/TestsGrid/'
          'tests_grid_controller_actions_part.dart',
    };

    for (final method in <String>[
      'openSearchTests',
      'openSavedTests',
      'openMyTestResults',
      'openMyTests',
      'openCreateTest',
      'openTestEntry',
    ]) {
      expect(serviceSource, contains(method));
    }

    expect(
      await File(checkedSources['tests shell']!).readAsString(),
      allOf(
        contains('openSavedTests()'),
        contains('openMyTestResults()'),
        contains('openMyTests()'),
        contains('openCreateTest()'),
        contains('openTestEntry()'),
      ),
    );
    expect(
      await File(checkedSources['tests search']!).readAsString(),
      contains('openSearchTests()'),
    );
    expect(
      await File(checkedSources['my tests']!).readAsString(),
      contains('openCreateTest()'),
    );
    expect(
      await File(checkedSources['tests grid']!).readAsString(),
      contains('openCreateTest(model: model)'),
    );
  });

  test('feature code does not open test routes directly', () async {
    const approvedFiles = <String>{
      'lib/Core/Services/education_test_navigation_service.dart',
    };
    final directRouteTokens = <String>[
      '=> SolveTest(',
      'Get.to(() => SolveTest',
      '=> SearchTests(',
      'Get.to(() => SearchTests',
      '=> SavedTests(',
      'Get.to(() => SavedTests',
      '=> MyTestResults(',
      'Get.to(() => MyTestResults',
      '=> MyTests(',
      'Get.to(() => MyTests',
      '=> CreateTest(',
      'Get.to(() => CreateTest',
      '=> const CreateTest(',
      'Get.to(() => const CreateTest',
      '=> TestEntry(',
      'Get.to(() => TestEntry',
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
      reason: 'Education test route creation should stay behind '
          'EducationTestNavigationService.',
    );
  });
}
