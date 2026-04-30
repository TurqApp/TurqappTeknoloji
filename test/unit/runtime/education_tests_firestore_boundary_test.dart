import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Education Tests module uses repositories for Firestore access',
      () async {
    final violations = <String>[];

    final testFiles = Directory('lib/Modules/Education/Tests')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in testFiles) {
      final source = await file.readAsString();
      if (!source.contains('FirebaseFirestore.instance')) continue;
      violations.add(file.path.replaceAll('\\', '/'));
    }

    expect(
      violations,
      isEmpty,
      reason: 'Education Tests screens/controllers should use repositories or '
          'services for Firestore reads and writes.',
    );
  });
}
