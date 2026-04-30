import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Splash startup uses local preference repository for direct reads',
      () async {
    final files = Directory('lib/Modules/Splash')
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
      reason: 'Splash should receive prefs through LocalPreferenceRepository.',
    );
  });
}
