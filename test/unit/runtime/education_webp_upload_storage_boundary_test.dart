import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'education image upload controllers delegate storage to WebpUploadService',
      () async {
    final checkedSources = <String, String>{
      'webp upload service': 'lib/Core/Services/webp_upload_service.dart',
      'antreman comments controller':
          'lib/Modules/Education/Antreman3/AntremanComments/antreman_comments_controller.dart',
      'antreman comments actions':
          'lib/Modules/Education/Antreman3/AntremanComments/antreman_comments_controller_actions_part.dart',
      'add test question controller':
          'lib/Modules/Education/Tests/AddTestQuestion/add_test_question_controller_library.dart',
      'add test question actions':
          'lib/Modules/Education/Tests/AddTestQuestion/add_test_question_controller_actions_part.dart',
    };

    final combinedSources = StringBuffer();
    final moduleSources = StringBuffer();
    for (final entry in checkedSources.entries) {
      final source = await File(entry.value).readAsString();
      combinedSources.writeln(source);
      if (entry.key != 'webp upload service') {
        moduleSources.writeln(source);
      }
    }
    final source = combinedSources.toString();
    final moduleSource = moduleSources.toString();

    expect(source, contains('WebpUploadService.uploadFileAsWebp'));
    expect(source, contains('storage ?? AppFirebaseStorage.instance'));
    expect(source, contains('comments/\${question.docID}/'));
    expect(source, contains('Testler/\$testID/'));
    expect(moduleSource, isNot(contains('AppFirebaseStorage.instance')));
    expect(
      moduleSource,
      isNot(contains('Core/Services/app_firebase_storage.dart')),
    );
  });
}
