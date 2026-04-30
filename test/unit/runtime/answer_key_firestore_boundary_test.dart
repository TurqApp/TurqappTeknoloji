import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AnswerKey module uses repositories instead of direct Firestore access',
      () async {
    final violations = <String>[];

    final answerKeyFiles = Directory('lib/Modules/Education/AnswerKey')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in answerKeyFiles) {
      final source = await file.readAsString();
      if (!source.contains('FirebaseFirestore.instance')) continue;
      violations.add(file.path.replaceAll('\\', '/'));
    }

    expect(
      violations,
      isEmpty,
      reason: 'AnswerKey screens/controllers should use repositories or '
          'services for Firestore reads and writes.',
    );
  });
}
