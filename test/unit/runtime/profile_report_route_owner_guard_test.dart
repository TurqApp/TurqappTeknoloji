import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SocialProfile and ReportUser route construction stays in services',
      () async {
    const approvedOwners = <String>{
      'lib/Core/Services/profile_navigation_service.dart',
      'lib/Core/Services/report_user_navigation_service.dart',
    };
    const forbiddenPatterns = <String>[
      'Get.to(() => SocialProfile',
      'Get.to<SocialProfile',
      'Get.to(SocialProfile',
      'Get.to(() => ReportUser',
      'Get.to<ReportUser',
      'Get.to(ReportUser',
      'Modules/SocialProfile/social_profile.dart',
      'Modules/SocialProfile/ReportUser/report_user.dart',
    ];

    final violations = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final path = file.path;
      if (approvedOwners.contains(path)) continue;
      final source = await file.readAsString();
      for (final pattern in forbiddenPatterns) {
        if (source.contains(pattern)) {
          violations.add('$path contains $pattern');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: violations.join('\n'),
    );
  });
}
