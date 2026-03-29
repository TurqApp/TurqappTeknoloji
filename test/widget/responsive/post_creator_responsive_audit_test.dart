import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/PostCreator/post_creator.dart';
import 'package:turqappv2/Modules/PostCreator/post_creator_controller.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/responsive_audit_expectations.dart';
import '../../helpers/widget_test_harness.dart';

class _ResponsiveAuditPostCreatorController extends PostCreatorController {
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  // ignore: must_call_super
  void onClose() {}

  @override
  void didChangeMetrics() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test',
          appId: 'test',
          messagingSenderId: 'test',
          projectId: 'test',
        ),
      );
    } on FirebaseException catch (error) {
      if (error.code != 'duplicate-app') {
        rethrow;
      }
    }
  });

  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  for (final variant in WidgetHarnessVariants.responsiveAuditMatrix) {
    testWidgets('PostCreator audit remains stable on ${variant.name}', (
      tester,
    ) async {
      Get.put<PostCreatorController>(_ResponsiveAuditPostCreatorController());

      await pumpApp(
        tester,
        PostCreator(),
        variant: variant,
      );
      await tester.pump(const Duration(milliseconds: 250));

      final findings = await collectResponsiveAuditFindings(
        tester,
        criticalCta: find.byKey(
          const ValueKey(IntegrationTestKeys.actionPostCreatorPublish),
        ),
        criticalInput: find.byType(TextField).first,
        header: find.byKey(
          const ValueKey(IntegrationTestKeys.screenPostCreator),
        ),
      );

      logResponsiveAuditFindings(
        screen: 'PostCreator',
        variant: variant.name,
        findings: findings,
      );
      expect(findings, isA<List<ResponsiveAuditFinding>>());
    });
  }

  testWidgets(
    'PostCreator keyboard audit keeps publish CTA visible on large text',
    (tester) async {
      Get.put<PostCreatorController>(_ResponsiveAuditPostCreatorController());

      await pumpApp(
        tester,
        PostCreator(),
        variant: WidgetHarnessVariants.phoneSmallAndroidLargeText,
      );
      await tester.pump(const Duration(milliseconds: 250));

      final input = find.byType(TextField).first;
      await tester.showKeyboard(input);
      await tester.pump();

      final findings = await collectResponsiveAuditFindings(
        tester,
        criticalCta: find.byKey(
          const ValueKey(IntegrationTestKeys.actionPostCreatorPublish),
        ),
        criticalInput: input,
        header: find.byKey(
          const ValueKey(IntegrationTestKeys.screenPostCreator),
        ),
      );

      logResponsiveAuditFindings(
        screen: 'PostCreatorKeyboard',
        variant: WidgetHarnessVariants.phoneSmallAndroidLargeText.name,
        findings: findings,
      );
      expect(findings, isA<List<ResponsiveAuditFinding>>());
    },
  );
}
