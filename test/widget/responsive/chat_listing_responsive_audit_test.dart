import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Models/chat_listing_model.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/responsive_audit_expectations.dart';
import '../../helpers/widget_test_harness.dart';

class _ResponsiveAuditChatListingController extends ChatListingController {
  _ResponsiveAuditChatListingController()
      : _seededChats = <ChatListingModel>[
          ChatListingModel(
            chatID: 'chat-1',
            userID: 'user-1',
            timeStamp: '0',
            deleted: const <String>[],
            nickname: 'audit_user_long_name',
            fullName: 'Audit User Display Name',
            avatarUrl: '',
            lastMessage: 'Bu bir audit mesajidir.',
            unreadCount: 0,
          ),
        ];

  final List<ChatListingModel> _seededChats;

  @override
  // ignore: must_call_super
  void onInit() {
    selectedTab.value = 'all';
    waiting.value = false;
    list.value = List<ChatListingModel>.from(_seededChats);
    filteredList.value = List<ChatListingModel>.from(_seededChats);
    search.addListener(_handleSearchChanged);
  }

  @override
  void onClose() {
    search.removeListener(_handleSearchChanged);
    super.onClose();
  }

  void _handleSearchChanged() {
    final query = search.text.trim().toLowerCase();
    filteredList.value = _seededChats.where((chat) {
      if (query.isEmpty) {
        return true;
      }
      return chat.nickname.toLowerCase().contains(query) ||
          chat.fullName.toLowerCase().contains(query) ||
          chat.lastMessage.toLowerCase().contains(query);
    }).toList(growable: false);
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
    testWidgets('ChatListing audit remains stable on ${variant.name}', (
      tester,
    ) async {
      Get.put<ChatListingController>(_ResponsiveAuditChatListingController());

      await pumpApp(
        tester,
        const ChatListing(),
        variant: variant,
      );

      final findings = await collectResponsiveAuditFindings(
        tester,
        criticalCta: find.byKey(
          const ValueKey(IntegrationTestKeys.actionChatCreate),
        ),
        criticalInput: find.byKey(
          const ValueKey(IntegrationTestKeys.inputChatSearch),
        ),
        header: find.byKey(
          const ValueKey(IntegrationTestKeys.screenChat),
        ),
      );

      logResponsiveAuditFindings(
        screen: 'ChatListing',
        variant: variant.name,
        findings: findings,
      );
      expect(findings, isA<List<ResponsiveAuditFinding>>());
    });
  }
}
