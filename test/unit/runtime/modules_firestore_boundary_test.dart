import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Modules do not instantiate FirebaseFirestore directly', () async {
    final files = Directory('lib/Modules')
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
      reason: 'Module code should access Firestore through repositories or '
          'approved Core services.',
    );
  });
}
