import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../integration_test/core/bootstrap/test_app_bootstrap.dart';

void main() {
  testWidgets('pressItKey invokes GestureDetector onTap callbacks', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GestureDetector(
            key: const ValueKey<String>('it-gesture-detector'),
            behavior: HitTestBehavior.opaque,
            onTap: () => tapped = true,
            child: const SizedBox(width: 120, height: 48),
          ),
        ),
      ),
    );

    await pressItKey(tester, 'it-gesture-detector', settlePumps: 1);

    expect(tapped, isTrue);
  });
}
