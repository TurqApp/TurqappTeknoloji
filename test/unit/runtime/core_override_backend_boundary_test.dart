import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Core override-friendly services use backend boundaries by default',
      () async {
    final checkedFiles = <String>[
      'lib/Core/Services/profile_manifest_sync_service.dart',
      'lib/Core/Services/scholarship_firestore_path.dart',
      'lib/Core/Services/qa_lab_remote_uploader.dart',
      'lib/Core/Services/qa_lab_remote_uploader_upload_part.dart',
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
      reason: 'Core services with optional test overrides should default to '
          'AppFirestore/AppFirebaseStorage.',
    );
  });
}
