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

class _ScreenTestChatListingController extends ChatListingController {
  _ScreenTestChatListingController({
    List<ChatListingModel>? seededChats,
  }) : _seededChats = seededChats ?? const <ChatListingModel>[];

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

  testWidgets('real chat listing screen renders search field and tabs', (
    tester,
  ) async {
    Get.put<ChatListingController>(_ScreenTestChatListingController());

    await pumpApp(tester, const ChatListing());

    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.screenChat)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.inputChatSearch)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.chatTabAll)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.chatTabUnread)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(IntegrationTestKeys.chatTabArchive)),
      findsOneWidget,
    );
  });

  testWidgets('real chat listing screen shows no-results state for empty search',
      (tester) async {
    Get.put<ChatListingController>(_ScreenTestChatListingController());

    await pumpApp(tester, const ChatListing());

    await tester.enterText(
      find.byKey(const ValueKey(IntegrationTestKeys.inputChatSearch)),
      'zzz',
    );
    await tester.pump();

    expect(find.text('common.no_results'), findsOneWidget);
  });
}
