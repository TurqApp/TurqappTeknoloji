import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Chat/chat.dart';
import 'package:turqappv2/Modules/Chat/chat_controller.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/responsive_audit_expectations.dart';
import '../../helpers/widget_test_harness.dart';

class _ResponsiveAuditChatController extends ChatController {
  _ResponsiveAuditChatController({
    required super.chatID,
    required super.userID,
  });

  @override
  // ignore: must_call_super
  void onInit() {
    selection.value = 0;
    nickname.value = 'audit_chat_user';
    fullName.value = 'Audit Chat Display Name';
    avatarUrl.value = '';
    chatBgPaletteIndex.value = 0;
    messages.clear();
  }

  @override
  // ignore: must_call_super
  void onClose() {
    textEditingController.dispose();
    scrollController.dispose();
    pageController.dispose();
    focus.dispose();
  }
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
    testWidgets('ChatView audit remains stable on ${variant.name}', (
      tester,
    ) async {
      const chatId = 'audit-chat';
      Get.put<ChatController>(
        _ResponsiveAuditChatController(
          chatID: chatId,
          userID: 'audit-user',
        ),
        tag: chatId,
      );

      await pumpApp(
        tester,
        ChatView(
          chatID: chatId,
          userID: 'audit-user',
        ),
        variant: variant,
      );

      final findings = await collectResponsiveAuditFindings(
        tester,
        criticalCta: find.byKey(
          const ValueKey(IntegrationTestKeys.actionChatMic),
        ),
        criticalInput: find.byKey(
          const ValueKey(IntegrationTestKeys.inputChatComposer),
        ),
        header: find.byKey(
          const ValueKey(IntegrationTestKeys.screenChatConversation),
        ),
      );

      logResponsiveAuditFindings(
        screen: 'ChatView',
        variant: variant.name,
        findings: findings,
      );
      expect(findings, isA<List<ResponsiveAuditFinding>>());
    });
  }

  testWidgets('ChatView keyboard audit keeps composer visible on large text', (
    tester,
  ) async {
    const chatId = 'audit-chat-keyboard';
    Get.put<ChatController>(
      _ResponsiveAuditChatController(
        chatID: chatId,
        userID: 'audit-user',
      ),
      tag: chatId,
    );

    await pumpApp(
      tester,
      ChatView(
        chatID: chatId,
        userID: 'audit-user',
        openKeyboard: true,
      ),
      variant: WidgetHarnessVariants.phoneSmallAndroidLargeText,
    );

    await tester.showKeyboard(
      find.byKey(const ValueKey(IntegrationTestKeys.inputChatComposer)),
    );
    await tester.pump();

    final findings = await collectResponsiveAuditFindings(
      tester,
      criticalCta: find.byKey(
        const ValueKey(IntegrationTestKeys.actionChatMic),
      ),
      criticalInput: find.byKey(
        const ValueKey(IntegrationTestKeys.inputChatComposer),
      ),
      header: find.byKey(
        const ValueKey(IntegrationTestKeys.screenChatConversation),
      ),
    );

    logResponsiveAuditFindings(
      screen: 'ChatViewKeyboard',
      variant: WidgetHarnessVariants.phoneSmallAndroidLargeText.name,
      findings: findings,
    );
    expect(findings, isA<List<ResponsiveAuditFinding>>());
  });
}
