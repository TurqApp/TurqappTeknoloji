import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_view.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_links_controller_library.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/responsive_audit_expectations.dart';
import '../../helpers/widget_test_harness.dart';

class _ResponsiveAuditProfileController extends ProfileController {
  @override
  // ignore: must_call_super
  void onInit() {
    headerNickname.value = 'audit_profile_user';
    headerDisplayName.value = 'Audit Profile Display Name';
    headerFirstName.value = 'Audit';
    headerLastName.value = 'Profile';
    headerBio.value = 'Audit bio for responsive layout checks.';
    followerCount.value = 128;
    followingCount.value = 256;
    postSelection.value = 99;
    mergedPosts.clear();
    allPosts.clear();
    photos.clear();
    videos.clear();
    reshares.clear();
    scheduledPosts.clear();
  }

  @override
  // ignore: must_call_super
  void onClose() {}
}

class _ResponsiveAuditSocialMediaController extends SocialMediaController {
  @override
  // ignore: must_call_super
  void onInit() {
    list.clear();
    isLoading.value = false;
  }

  @override
  // ignore: must_call_super
  void onClose() {
    textController.dispose();
    urlController.dispose();
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
    testWidgets('ProfileView audit remains stable on ${variant.name}', (
      tester,
    ) async {
      Get.put<ProfileController>(_ResponsiveAuditProfileController());
      Get.put<SocialMediaController>(_ResponsiveAuditSocialMediaController());

      await pumpApp(
        tester,
        const ProfileView(),
        variant: variant,
      );

      final findings = await collectResponsiveAuditFindings(
        tester,
        criticalCta: find.byKey(
          const ValueKey(IntegrationTestKeys.profileFollowersCounter),
        ),
        header: find.byKey(
          const ValueKey(IntegrationTestKeys.screenProfile),
        ),
      );

      logResponsiveAuditFindings(
        screen: 'MyProfile',
        variant: variant.name,
        findings: findings,
      );
      expectNoResponsiveAuditFailures(
        findings,
        reason: 'MyProfile ${variant.name} responsive audit fail verdi.',
      );
    });
  }
}
