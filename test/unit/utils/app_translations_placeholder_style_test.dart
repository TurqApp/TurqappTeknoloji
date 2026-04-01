import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app translations use GetX parameter placeholder style', () async {
    final file = File('lib/Core/Localization/app_translations.dart');
    final contents = await file.readAsString();
    final legacyPlaceholder = RegExp(r'\{[A-Za-z_][A-Za-z0-9_]*\}');

    expect(
      legacyPlaceholder.allMatches(contents),
      isEmpty,
      reason:
          'Use @param placeholder style in app_translations.dart to keep trParams replacements working.',
    );
  });
}
