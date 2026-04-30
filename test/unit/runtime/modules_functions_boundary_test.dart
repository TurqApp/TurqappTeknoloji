import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Modules access Cloud Functions through AppCloudFunctions', () async {
    final files = Directory('lib/Modules')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final violations = <String>[];

    for (final file in files) {
      final source = await file.readAsString();
      if (!source.contains('FirebaseFunctions.instance')) continue;
      violations.add(file.path.replaceAll('\\', '/'));
    }

    expect(
      violations,
      isEmpty,
      reason: 'Module code should access callable functions through '
          'AppCloudFunctions or a domain service.',
    );
  });
}
