import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EditPost uses repositories for direct Firestore access', () async {
    final files = Directory('lib/Modules/EditPost')
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
      reason: 'EditPost should use PostRepository for direct Firestore access.',
    );
  });
}
