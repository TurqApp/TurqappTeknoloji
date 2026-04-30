import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app services keep backend singleton access behind wrappers', () async {
    final allowedFiles = <String>{
      'lib/Core/Services/app_firestore.dart',
      'lib/Core/Services/app_cloud_functions.dart',
      'lib/Core/Services/app_firebase_storage.dart',
    };
    final roots = <String>[
      'lib/Core/Services',
      'lib/Services',
    ];
    final violations = <String>[];

    for (final root in roots) {
      final files = Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      for (final file in files) {
        final path = file.path.replaceAll('\\', '/');
        if (allowedFiles.contains(path)) continue;
        final lines = await file.readAsLines();
        for (var index = 0; index < lines.length; index++) {
          final line = lines[index];
          if (line.contains('AppFirestore.instance') ||
              line.contains('AppCloudFunctions.instance') ||
              line.contains('AppFirebaseStorage.instance')) {
            continue;
          }
          if (line.contains('FirebaseFirestore.instance') ||
              line.contains('FirebaseFunctions.instance') ||
              line.contains('FirebaseFunctions.instanceFor') ||
              line.contains('FirebaseStorage.instance') ||
              line.contains('firebase_storage.FirebaseStorage.instance')) {
            violations.add('$path:${index + 1}');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Service code should access Firestore, Cloud Functions, and '
          'Storage through AppFirestore/AppCloudFunctions/AppFirebaseStorage.',
    );
  });
}
