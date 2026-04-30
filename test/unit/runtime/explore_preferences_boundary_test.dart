import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Explore module uses local preference repository', () async {
    final files = Directory('lib/Modules/Explore')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final violations = <String>[];

    for (final file in files) {
      final source = await file.readAsString();
      if (!source.contains('SharedPreferences.getInstance')) continue;
      violations.add(file.path.replaceAll('\\', '/'));
    }

    expect(
      violations,
      isEmpty,
      reason: 'Explore should use LocalPreferenceRepository for preferences.',
    );
  });
}
