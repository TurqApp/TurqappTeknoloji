import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PracticeExam write flows use repositories for Firestore access',
      () async {
    final checkedDirectories = <String>[
      'lib/Modules/Education/PracticeExams/SinavHazirla',
      'lib/Modules/Education/PracticeExams/SinavSorusuHazirla',
      'lib/Modules/Education/PracticeExams/SoruContent',
      'lib/Modules/Education/PracticeExams/DenemeSinaviPreview',
      'lib/Modules/Education/PracticeExams/DenemeSinaviYap',
    ];
    final violations = <String>[];

    for (final directory in checkedDirectories) {
      final files = Directory(directory)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in files) {
        final source = await file.readAsString();
        if (!source.contains('FirebaseFirestore.instance')) continue;
        violations.add(file.path.replaceAll('\\', '/'));
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'PracticeExam write screens/controllers should use '
          'PracticeExamRepository for Firestore writes.',
    );
  });
}
