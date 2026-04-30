import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Chat module uses local preference repository', () async {
    final files = Directory('lib/Modules/Chat')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList(growable: false);
    final violations = <String>[];

    for (final file in files) {
      final source = await file.readAsString();
      if (!source.contains('SharedPreferences.getInstance')) continue;
      violations.add(file.path);
    }

    expect(
      violations,
      isEmpty,
      reason: 'Chat module should use LocalPreferenceRepository for prefs.',
    );
  });
}
