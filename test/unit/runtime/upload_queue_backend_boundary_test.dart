import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UploadQueueService uses backend boundary services', () async {
    final checkedFiles = <String>[
      'lib/Core/Services/upload_queue_service.dart',
      'lib/Core/Services/upload_queue_service_post_shell_content_part.dart',
      'lib/Core/Services/upload_queue_service_processing_part.dart',
    ];
    final violations = <String>[];

    for (final path in checkedFiles) {
      final source = await File(path).readAsString();
      if (source.split('\n').any((line) {
        if (line.contains('AppFirestore.instance') ||
            line.contains('AppFirebaseStorage.instance')) {
          return false;
        }
        return line.contains('FirebaseFirestore.instance') ||
            line.contains('FirebaseStorage.instance');
      })) {
        violations.add(path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'UploadQueueService should access Firestore/Storage through '
          'AppFirestore/AppFirebaseStorage.',
    );
  });
}
