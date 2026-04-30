import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Modules access Storage through AppFirebaseStorage', () async {
    final files = Directory('lib/Modules')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final violations = <String>[];

    for (final file in files) {
      final source = await file.readAsString();
      final hasDirectStorage = source.split('\n').any((line) {
        if (line.contains('AppFirebaseStorage.instance')) return false;
        return line.contains('FirebaseStorage.instance') ||
            line.contains('firebase_storage.FirebaseStorage.instance');
      });
      if (!hasDirectStorage) continue;
      violations.add(file.path.replaceAll('\\', '/'));
    }

    expect(
      violations,
      isEmpty,
      reason: 'Module code should access Firebase Storage through '
          'AppFirebaseStorage or a domain upload service.',
    );
  });
}
