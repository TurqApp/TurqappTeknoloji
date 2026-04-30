import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Scholarships module uses repositories for Firestore access', () async {
    final files = Directory('lib/Modules/Education/Scholarships')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final violations = <String>[];

    for (final file in files) {
      final source = await file.readAsString();
      if (!source.contains('FirebaseFirestore.instance')) continue;
      violations.add(file.path.replaceAll('\\', '/'));
    }

    expect(
      violations,
      isEmpty,
      reason: 'Scholarship screens/controllers should use repositories '
          'for Firestore access.',
    );
  });
}
