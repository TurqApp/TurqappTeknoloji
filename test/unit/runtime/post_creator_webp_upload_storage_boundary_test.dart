import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PostCreator WebP uploads delegate storage to WebpUploadService',
      () async {
    final checkedSources = <String, String>{
      'post creator publish':
          'lib/Modules/PostCreator/post_creator_controller_publish_part.dart',
      'post creator publish upload':
          'lib/Modules/PostCreator/post_creator_controller_publish_upload_part.dart',
    };

    final combinedSources = StringBuffer();
    for (final sourcePath in checkedSources.values) {
      combinedSources.writeln(await File(sourcePath).readAsString());
    }
    final source = combinedSources.toString();

    expect(source, contains('WebpUploadService.uploadBytesAsWebp'));
    expect(source, contains('Posts/\$docID/image_\$j'));
    expect(source, contains('Posts/\$docID/thumbnail'));
    expect(source, contains('Posts/\$docID/video.mp4'));
    expect(source, contains('AppFirebaseStorage.instance'));
    expect(source, isNot(contains('storage: AppFirebaseStorage.instance')));
  });
}
