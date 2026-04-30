import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OfflineModeService action replay uses AppFirestore boundary', () async {
    final checkedFiles = <String>[
      'lib/Services/offline_mode_service.dart',
      'lib/Services/offline_mode_service_action_part.dart',
    ];
    final violations = <String>[];

    for (final path in checkedFiles) {
      final source = await File(path).readAsString();
      if (source.split('\n').any((line) {
        if (line.contains('AppFirestore.instance')) return false;
        return line.contains('FirebaseFirestore.instance');
      })) {
        violations.add(path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Offline queued action replay should access Firestore through '
          'AppFirestore.',
    );
  });
}
