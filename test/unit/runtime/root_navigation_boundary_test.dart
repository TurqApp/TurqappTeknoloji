import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('root-clearing navigation stays behind AppRootNavigationService',
      () async {
    const approvedFile = 'lib/Runtime/app_root_navigation_service.dart';
    const rootClearingPatterns = <String>[
      'Get.offAll',
      'Get.offAllNamed',
      'Get.offAllUntil',
      'Get.offNamedUntil',
      'Get.offUntil',
      'Navigator.pushAndRemoveUntil',
      'Navigator.pushNamedAndRemoveUntil',
      'Navigator.popUntil',
      '.pushAndRemoveUntil',
      '.pushNamedAndRemoveUntil',
      '.popUntil',
    ];
    final violations = <String>[];

    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (normalizedPath == approvedFile) continue;

      final source = await file.readAsString();
      final usesRootClearingNavigation = rootClearingPatterns.any(
        source.contains,
      );
      if (!usesRootClearingNavigation) continue;

      violations.add(normalizedPath);
    }

    expect(
      violations,
      isEmpty,
      reason: 'Use AppRootNavigationService for root-clearing navigation so '
          'auth, splash, and session exits share one routing boundary.',
    );
  });

  test('authenticated home root navigation stays in approved flow boundaries',
      () async {
    const approvedFiles = <String>{
      'lib/Runtime/app_root_navigation_service.dart',
      'lib/Modules/Splash/splash_view_startup_part.dart',
      'lib/Modules/SignIn/sign_in_controller_auth_part.dart',
      'lib/Modules/SignIn/sign_in_controller_signup_part.dart',
      'lib/Core/NotifyReader/notify_reader_controller_navigation_part.dart',
      'lib/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller_submission_part.dart',
    };
    const patterns = <String>[
      'AppRootNavigationService.offAllToAuthenticatedHome',
      'AppRootNavigationService.offToAuthenticatedHome',
    ];
    final violations = <String>[];

    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (approvedFiles.contains(normalizedPath)) continue;

      final source = await file.readAsString();
      final usesAuthenticatedHomeRootNav = patterns.any(source.contains);
      if (!usesAuthenticatedHomeRootNav) continue;

      violations.add(normalizedPath);
    }

    expect(
      violations,
      isEmpty,
      reason: 'Authenticated-home root navigation should stay in startup, '
          'auth, notification-return, and approved post-submit boundaries.',
    );
  });
}
