import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('related education detail replacements stay behind navigation service',
      () async {
    final serviceSource = await File(
      'lib/Core/Services/education_detail_navigation_service.dart',
    ).readAsString();
    final jobSource = await File(
      'lib/Modules/JobFinder/JobDetails/job_details_reviews_part.dart',
    ).readAsString();
    final jobContentSource = await File(
      'lib/Modules/JobFinder/JobContent/job_content.dart',
    ).readAsString();
    final tutoringSource = await File(
      'lib/Modules/Education/Tutoring/TutoringDetail/'
      'tutoring_detail_sections_part.dart',
    ).readAsString();
    final tutoringListingSource = await File(
      'lib/Modules/Education/Tutoring/tutoring_widget_builder.dart',
    ).readAsString();
    final deepLinkSource = await File(
      'lib/Core/Services/deep_link_service_open_part.dart',
    ).readAsString();
    final educationCtaSource = await File(
      'lib/Core/Services/education_feed_cta_navigation_service.dart',
    ).readAsString();
    final notifyReaderSource = await File(
      'lib/Core/NotifyReader/notify_reader_controller_navigation_part.dart',
    ).readAsString();

    expect(serviceSource, contains('openJobDetails'));
    expect(serviceSource, contains('openTutoringDetail'));
    expect(serviceSource, contains('replaceWithJobDetails'));
    expect(serviceSource, contains('replaceWithTutoringDetail'));
    expect(jobContentSource, contains('openJobDetails(model)'));
    expect(tutoringListingSource, contains('openTutoringDetail(tutoring)'));
    expect(deepLinkSource, contains('openJobDetails(model)'));
    expect(educationCtaSource, contains('openJobDetails('));
    expect(educationCtaSource, contains('openTutoringDetail('));
    expect(notifyReaderSource, contains('openJobDetails(model)'));
    expect(notifyReaderSource, contains('openTutoringDetail(model)'));
    expect(jobSource, contains('replaceWithJobDetails(item)'));
    expect(tutoringSource, contains('replaceWithTutoringDetail(item)'));
    expect(jobContentSource, isNot(contains('Get.to(() => JobDetails')));
    expect(
      tutoringListingSource,
      isNot(contains('Get.to(() => TutoringDetail')),
    );
    expect(deepLinkSource, isNot(contains('Get.to(() => JobDetails')));
    expect(educationCtaSource, isNot(contains('Get.to(() => JobDetails')));
    expect(
      educationCtaSource,
      isNot(contains('Get.to(() => TutoringDetail')),
    );
    expect(notifyReaderSource, isNot(contains('Get.to<JobDetails>')));
    expect(notifyReaderSource, isNot(contains('Get.to<TutoringDetail>')));
    expect(jobSource, isNot(contains('Get.off(() => JobDetails')));
    expect(tutoringSource, isNot(contains('Get.off(() => TutoringDetail')));
  });

  test('education entry routes stay behind navigation service', () async {
    final serviceSource = await File(
      'lib/Core/Services/education_detail_navigation_service.dart',
    ).readAsString();
    final educationActionsSource = await File(
      'lib/Modules/Education/education_view_actions_part.dart',
    ).readAsString();
    final tutoringViewSource = await File(
      'lib/Modules/Education/Tutoring/tutoring_view.dart',
    ).readAsString();
    final tutoringContentSource = await File(
      'lib/Modules/Education/Tutoring/tutoring_view_content_part.dart',
    ).readAsString();
    final tutoringShellSource = await File(
      'lib/Modules/Education/Tutoring/tutoring_view_shell_content_part.dart',
    ).readAsString();
    final tutoringCategorySource = await File(
      'lib/Modules/Education/Tutoring/tutoring_category.dart',
    ).readAsString();
    final tutoringDetailSource = await File(
      'lib/Modules/Education/Tutoring/TutoringDetail/'
      'tutoring_detail_body_part.dart',
    ).readAsString();
    final jobDetailsSource = await File(
      'lib/Modules/JobFinder/JobDetails/job_details_controller_actions_part.dart',
    ).readAsString();

    expect(serviceSource, contains('openTutoringSearch'));
    expect(serviceSource, contains('openMyTutoringApplications'));
    expect(serviceSource, contains('openCreateTutoring'));
    expect(serviceSource, contains('openMyTutorings'));
    expect(serviceSource, contains('openSavedTutorings'));
    expect(serviceSource, contains('openLocationBasedTutoring'));
    expect(serviceSource, contains('openTutoringCategory'));
    expect(serviceSource, contains('openMyJobApplications'));
    expect(serviceSource, contains('openJobCreator'));
    expect(serviceSource, contains('openMyJobAds'));
    expect(serviceSource, contains('openCareerProfile'));
    expect(serviceSource, contains('openSavedJobs'));

    expect(educationActionsSource, contains('openTutoringSearch()'));
    expect(tutoringContentSource, contains('openTutoringSearch()'));
    expect(tutoringShellSource, contains('openMyTutoringApplications()'));
    expect(tutoringCategorySource, contains('openTutoringCategory'));
    expect(tutoringDetailSource, contains('openCreateTutoring('));
    expect(jobDetailsSource, contains('openJobCreator(existingJob:'));
    expect(educationActionsSource, contains('openMyJobApplications()'));
    expect(educationActionsSource, contains('openJobCreator()'));
    expect(educationActionsSource, contains('openMyJobAds()'));
    expect(educationActionsSource, contains('openCareerProfile()'));
    expect(educationActionsSource, contains('openSavedJobs()'));

    final outsideNavigationService = [
      educationActionsSource,
      tutoringViewSource,
      tutoringContentSource,
      tutoringShellSource,
      tutoringCategorySource,
      tutoringDetailSource,
      jobDetailsSource,
    ].join('\n');

    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => const TutoringSearch')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => MyTutoringApplications')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(CreateTutoringView')),
    );
    expect(outsideNavigationService, isNot(contains('Get.to(MyTutorings')));
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => SavedTutorings')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => LocationBasedTutoring')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => TutoringContent')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => MyApplications')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => JobCreator')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to<JobModel?>(JobCreator')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => MyJobAds')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => CareerProfile')),
    );
    expect(
      outsideNavigationService,
      isNot(contains('Get.to(() => SavedJobs')),
    );
  });
}
