import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('become verified account opens stay behind navigation service',
      () async {
    final serviceSource = await File(
      'lib/Core/Services/verified_account_navigation_service.dart',
    ).readAsString();
    final checkedSources = <String, String>{
      'practice exams':
          'lib/Modules/Education/PracticeExams/deneme_sinavlari_actions_part.dart',
      'profile settings':
          'lib/Modules/Profile/Settings/settings_sections_account_part.dart',
      'my profile':
          'lib/Modules/Profile/MyProfile/profile_view_actions_part.dart',
    };

    expect(serviceSource, contains('openBecomeVerifiedAccount'));
    expect(serviceSource, contains('BecomeVerifiedAccount()'));

    final combinedSources = StringBuffer();
    for (final entry in checkedSources.entries) {
      final source = await File(entry.value).readAsString();
      combinedSources.writeln(source);
      expect(
        source,
        contains('openBecomeVerifiedAccount'),
        reason: '${entry.key} should delegate verified-account navigation.',
      );
    }

    expect(
      combinedSources.toString(),
      isNot(contains('Get.to(() => BecomeVerifiedAccount')),
    );
  });
}
