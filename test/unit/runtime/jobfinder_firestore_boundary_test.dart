import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JobFinder module uses repositories instead of direct Firestore access',
      () async {
    final violations = <String>[];

    final jobFinderFiles = Directory('lib/Modules/JobFinder')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in jobFinderFiles) {
      final source = await file.readAsString();
      if (!source.contains('FirebaseFirestore.instance')) continue;
      violations.add(file.path.replaceAll('\\', '/'));
    }

    expect(
      violations,
      isEmpty,
      reason: 'JobFinder screens/controllers should use repositories or '
          'services for Firestore reads and writes.',
    );
  });
}
