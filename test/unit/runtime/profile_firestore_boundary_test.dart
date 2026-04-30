import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile module uses repositories instead of direct Firestore access',
      () async {
    final violations = <String>[];

    final profileFiles = Directory('lib/Modules/Profile')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in profileFiles) {
      final source = await file.readAsString();
      if (!source.contains('FirebaseFirestore.instance')) continue;
      violations.add(file.path.replaceAll('\\', '/'));
    }

    expect(
      violations,
      isEmpty,
      reason: 'Profile screens/controllers should use repositories or '
          'services for Firestore reads and writes.',
    );
  });
}
