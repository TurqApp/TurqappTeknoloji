import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app code keeps FirebaseMessaging singleton behind app boundary',
      () async {
    const allowedOwner = 'lib/Core/Services/app_firebase_messaging.dart';
    final violations = <String>[];

    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (normalizedPath == allowedOwner) continue;

      final lines = await file.readAsLines();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        final opensSingleton = line.contains('FirebaseMessaging.instance') &&
            !line.contains('AppFirebaseMessaging.instance');
        final registersBackgroundHandler =
            line.contains('FirebaseMessaging.onBackgroundMessage') &&
                !line.contains('AppFirebaseMessaging.onBackgroundMessage');
        if (!opensSingleton && !registersBackgroundHandler) continue;
        violations.add('$normalizedPath:${index + 1}');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Use AppFirebaseMessaging instead of direct FirebaseMessaging '
          'singleton or background-handler access.',
    );
  });
}
