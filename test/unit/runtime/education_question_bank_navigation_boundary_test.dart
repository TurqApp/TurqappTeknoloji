import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('question bank entry opens stay behind navigation service', () async {
    final serviceSource = await File(
      'lib/Core/Services/education_question_bank_navigation_service.dart',
    ).readAsString();
    final educationActionsSource = await File(
      'lib/Modules/Education/education_view_actions_part.dart',
    ).readAsString();
    final antremanViewSource = await File(
      'lib/Modules/Education/Antreman3/antreman_view.dart',
    ).readAsString();
    final antremanShellSource = await File(
      'lib/Modules/Education/Antreman3/antreman_view_shell_content_part.dart',
    ).readAsString();
    final questionContentSource = await File(
      'lib/Modules/Education/Antreman3/question_content_shell_content_part.dart',
    ).readAsString();

    expect(serviceSource, contains('openThenSolve'));
    expect(serviceSource, contains('openPastQuestionResults'));
    expect(educationActionsSource, contains('openThenSolve()'));
    expect(educationActionsSource, contains('openPastQuestionResults()'));
    expect(antremanViewSource, contains('openThenSolve()'));
    expect(antremanShellSource, contains('openThenSolve()'));
    expect(questionContentSource, contains('openThenSolve()'));
    expect(antremanViewSource, contains('controller.fetchSavedQuestions()'));
    expect(antremanShellSource, contains('controller.fetchSavedQuestions()'));
    expect(questionContentSource,
        contains('controller.savedQuestionsList.clear()'));
    expect(questionContentSource, contains('controller.fetchSavedQuestions()'));

    final outsideNavigationService = [
      educationActionsSource,
      antremanViewSource,
      antremanShellSource,
      questionContentSource,
    ].join('\n');

    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => ThenSolve')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => CikmisSoruSonuclar')),
    );
  });
}
