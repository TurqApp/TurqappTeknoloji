import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Future<void> pumpApp(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    GetMaterialApp(
      home: child,
    ),
  );
  await tester.pump();
}
