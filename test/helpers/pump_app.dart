import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test_harness.dart';

Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  WidgetHarnessVariant variant = WidgetHarnessVariants.phoneAndroid,
  Locale locale = const Locale('tr'),
  ThemeData? theme,
  bool wrapInScaffold = false,
}) async {
  await configureHarnessSurface(
    tester,
    variant: variant,
  );
  await tester.pumpWidget(
    buildHarnessApp(
      child,
      variant: variant,
      locale: locale,
      theme: theme,
      wrapInScaffold: wrapInScaffold,
    ),
  );
  await tester.pump();
}
