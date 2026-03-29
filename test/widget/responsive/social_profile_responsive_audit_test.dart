import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Chat/ChatListing/chat_listing_controller.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile_controller.dart';
import 'package:turqappv2/Modules/Story/StoryHighlights/story_highlights_controller.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/responsive_audit_expectations.dart';
import '../../helpers/widget_test_harness.dart';

class _ResponsiveAuditSocialProfileController extends SocialProfileController {
  _ResponsiveAuditSocialProfileController({required super.userID});

  @override
  // ignore: must_call_super
  void onInit() {
    nickname.value = 'audit_social_profile_with_long_name';
    displayName.value = 'Audit Social Display Name';
    rozet.value = 'verified';
    bio.value = 'Audit social bio for responsive layout checks.';
    totalFollower.value = 320;
    totalFollowing.value = 640;
    totalPosts.value = 42;
    totalLikes.value = 999;
    complatedCheck.value = true;
    takipEdiyorum.value = false;
    mailIzin.value = true;
    aramaIzin.value = true;
    email.value = 'audit@example.com';
    phoneNumber.value = '5551112233';
    postSelection.value = 99;
    allPosts.clear();
    photos.clear();
    reshares.clear();
    scheduledPosts.clear();
    socialMediaList.clear();
  }

  @override
  // ignore: must_call_super
  void onClose() {
    scrollController.dispose();
  }
}

class _ResponsiveAuditChatListingController extends ChatListingController {
  @override
  // ignore: must_call_super
  void onInit() {
    selectedTab.value = 'all';
    waiting.value = false;
    list.clear();
    filteredList.clear();
  }

  @override
  // ignore: must_call_super
  void onClose() {}
}

class _ResponsiveAuditStoryHighlightsController
    extends StoryHighlightsController {
  _ResponsiveAuditStoryHighlightsController({required super.userId});

  @override
  // ignore: must_call_super
  void onInit() {
    highlights.clear();
    isLoading.value = false;
  }

  @override
  // ignore: must_call_super
  void onClose() {}
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
    testWidgets('SocialProfile audit remains stable on ${variant.name}', (
      tester,
    ) async {
      const userId = 'audit-social-user';
      Get.put<ChatListingController>(_ResponsiveAuditChatListingController());
      Get.put<SocialProfileController>(
        _ResponsiveAuditSocialProfileController(userID: userId),
        tag: userId,
      );
      Get.put<StoryHighlightsController>(
        _ResponsiveAuditStoryHighlightsController(userId: userId),
        tag: 'highlights_$userId',
      );

      await pumpApp(
        tester,
        const SocialProfile(userID: userId),
        variant: variant,
      );

      final findings = await collectResponsiveAuditFindings(
        tester,
        criticalCta: find.byType(TextButton).first,
        header: find.byKey(
          const ValueKey(IntegrationTestKeys.screenSocialProfile),
        ),
      );

      logResponsiveAuditFindings(
        screen: 'SocialProfile',
        variant: variant.name,
        findings: findings,
      );
      expectNoResponsiveAuditFailures(
        findings,
        reason: 'SocialProfile ${variant.name} responsive audit fail verdi.',
      );
    });
  }
}
