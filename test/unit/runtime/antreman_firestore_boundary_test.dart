import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Antreman module uses repositories for Firestore access', () async {
    final files = Directory('lib/Modules/Education/Antreman3')
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
      reason: 'Antreman screens/controllers should use repositories/services '
          'for Firestore access.',
    );
  });
}
