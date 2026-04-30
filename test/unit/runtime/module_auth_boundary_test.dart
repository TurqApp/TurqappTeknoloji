import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('module-level FirebaseAuth access stays behind approved boundary',
      () async {
    final approvedFiles = <String>{};
    final violations = <String>[];

    final moduleFiles = Directory('lib/Modules')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in moduleFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (approvedFiles.contains(normalizedPath)) continue;

      final lines = await file.readAsLines();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (!line.contains('FirebaseAuth.instance')) continue;
        if (line.contains('AppFirebaseAuth.instance')) continue;
        violations.add('$normalizedPath:${index + 1}');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Use AppFirebaseAuth, CurrentUserService, or an approved auth '
          'application service instead of direct FirebaseAuth.instance access '
          'from modules.',
    );
  });
}
