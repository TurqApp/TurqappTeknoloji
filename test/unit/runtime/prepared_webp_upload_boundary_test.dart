import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prepared WebP uploads stay behind WebpUploadService', () async {
    final checkedSources = <String, String>{
      'webp upload service': 'lib/Core/Services/webp_upload_service.dart',
      'webp upload part':
          'lib/Core/Services/webp_upload_service_upload_part.dart',
      'create book controller':
          'lib/Modules/Education/AnswerKey/CreateBook/create_book_controller.dart',
      'create book submission':
          'lib/Modules/Education/AnswerKey/CreateBook/create_book_controller_submission_part.dart',
      'create scholarship controller':
          'lib/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart',
      'create scholarship fields':
          'lib/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller_fields_part.dart',
      'create scholarship submission':
          'lib/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller_submission_part.dart',
    };

    final combinedSources = StringBuffer();
    for (final sourcePath in checkedSources.values) {
      combinedSources.writeln(await File(sourcePath).readAsString());
    }
    final source = combinedSources.toString();

    expect(source, contains('uploadPreparedWebpBytes'));
    expect(source, contains('books/\$docID/cover'));
    expect(source, contains("storagePath: storagePath"));
    expect(source, contains("scholarships/\${isLogo ? 'logos' : 'images'}"));
    expect(source, contains('scholarships/templates/'));
    expect(
      source,
      isNot(contains('AppFirebaseStorage.instance.ref().child')),
    );
    expect(source, isNot(contains('final storage = AppFirebaseStorage')));
  });
}
