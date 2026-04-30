import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'test and practice exam image uploads delegate storage to WebpUploadService',
      () async {
    final checkedSources = <String, String>{
      'create test controller':
          'lib/Modules/Education/Tests/CreateTest/create_test_controller.dart',
      'create test actions':
          'lib/Modules/Education/Tests/CreateTest/create_test_controller_actions_part.dart',
      'create question controller':
          'lib/Modules/Education/Tests/CreateTestQuestionContent/create_test_question_content_controller_library.dart',
      'create question actions':
          'lib/Modules/Education/Tests/CreateTestQuestionContent/create_test_question_content_controller_actions_part.dart',
      'practice question view':
          'lib/Modules/Education/PracticeExams/SoruContent/soru_content.dart',
      'practice question actions':
          'lib/Modules/Education/PracticeExams/SoruContent/soru_content_actions_part.dart',
      'practice exam prepare controller':
          'lib/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla_controller.dart',
      'practice exam prepare submission':
          'lib/Modules/Education/PracticeExams/SinavHazirla/sinav_hazirla_controller_submission_part.dart',
    };

    final combinedSources = StringBuffer();
    for (final sourcePath in checkedSources.values) {
      combinedSources.writeln(await File(sourcePath).readAsString());
    }
    final source = combinedSources.toString();

    expect(source, contains('WebpUploadService.uploadFileAsWebp'));
    expect(source, contains('Testler/\${testID.value}/'));
    expect(source, contains('Testler/\$testID/'));
    expect(source, contains('practiceExams/\$mainID/questions/'));
    expect(source, contains('practiceExams/\$docID/cover'));
    expect(source, isNot(contains('storage: AppFirebaseStorage.instance')));
    expect(
      source,
      isNot(contains('Core/Services/app_firebase_storage.dart')),
    );
  });
}
