import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('education and deep-link profile opens stay behind navigation service',
      () async {
    final serviceSource = await File(
      'lib/Core/Services/profile_navigation_service.dart',
    ).readAsString();
    final checkedSources = <String, String>{
      'deep link': 'lib/Core/Services/deep_link_service_open_part.dart',
      'antreman score': 'lib/Modules/Education/Antreman3/AntremanScore/'
          'antreman_score_widgets_part.dart',
      'booklet preview': 'lib/Modules/Education/AnswerKey/BookletPreview/'
          'booklet_preview_widgets_part.dart',
      'practice exam preview':
          'lib/Modules/Education/PracticeExams/DenemeSinaviPreview/'
              'deneme_sinavi_preview_sections_part.dart',
      'scholarship applicant':
          'lib/Modules/Education/Scholarships/ScholarshipApplicationsContent/'
              'applicant_profile_widgets_part.dart',
      'scholarship detail':
          'lib/Modules/Education/Scholarships/ScholarshipDetail/'
              'scholarship_detail_view_helpers_part.dart',
      'scholarship providers':
          'lib/Modules/Education/Scholarships/ScholarshipProviders/'
              'scholarship_providers_view.dart',
      'scholarships user':
          'lib/Modules/Education/Scholarships/scholarships_view_user_part.dart',
      'tests grid': 'lib/Modules/Education/Tests/TestsGrid/'
          'tests_grid_controller_actions_part.dart',
      'tutoring application review':
          'lib/Modules/Education/Tutoring/TutoringApplicationReview/'
              'tutoring_application_review_actions_part.dart',
      'tutoring detail': 'lib/Modules/Education/Tutoring/TutoringDetail/'
          'tutoring_detail_body_part.dart',
    };

    expect(serviceSource, contains('openSocialProfile'));
    expect(serviceSource, contains('openMyProfile'));
    expect(serviceSource, contains('SocialProfile(userID: normalizedUserId)'));
    expect(serviceSource, contains('ProfileView()'));

    final combinedSources = StringBuffer();
    for (final entry in checkedSources.entries) {
      final source = await File(entry.value).readAsString();
      combinedSources.writeln(source);
      expect(
        source,
        contains('ProfileNavigationService'),
        reason: '${entry.key} should delegate profile opening.',
      );
    }

    final outsideNavigationService = combinedSources.toString();
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => SocialProfile')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(SocialProfile')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => ProfileView')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(ProfileView')),
    );
  });
}
