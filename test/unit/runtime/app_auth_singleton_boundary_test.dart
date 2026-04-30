import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app code keeps FirebaseAuth singleton behind approved boundaries',
      () async {
    final allowedFiles = <String>{
      'lib/Core/Services/app_firebase_auth.dart',
    };
    final violations = <String>[];

    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final path = file.path.replaceAll('\\', '/');
      if (allowedFiles.contains(path)) continue;

      final lines = await file.readAsLines();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (!line.contains('FirebaseAuth.instance')) continue;
        if (line.contains('AppFirebaseAuth.instance')) continue;
        violations.add('$path:${index + 1}');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Use AppFirebaseAuth or CurrentUserService instead of direct '
          'FirebaseAuth.instance access.',
    );
  });
}
