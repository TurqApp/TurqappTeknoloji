import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JobFinder profile, report, and CV opens stay behind services',
      () async {
    final detailNavigationSource = await File(
      'lib/Core/Services/education_detail_navigation_service.dart',
    ).readAsString();
    final checkedSources = <String, String>{
      'job details': 'lib/Modules/JobFinder/JobDetails/job_details.dart',
      'job details body':
          'lib/Modules/JobFinder/JobDetails/job_details_body_part.dart',
      'job details meta':
          'lib/Modules/JobFinder/JobDetails/job_details_meta_part.dart',
      'job details actions':
          'lib/Modules/JobFinder/JobDetails/job_details_actions_part.dart',
      'career profile':
          'lib/Modules/JobFinder/CareerProfile/career_profile_content_part.dart',
      'finding job apply':
          'lib/Modules/JobFinder/FindingJobApply/finding_job_apply.dart',
      'application review':
          'lib/Modules/JobFinder/ApplicationReview/application_review_content_part.dart',
    };

    expect(detailNavigationSource, contains('openCv'));
    expect(detailNavigationSource, contains('Cv()'));

    final combinedSources = StringBuffer();
    for (final sourcePath in checkedSources.values) {
      combinedSources.writeln(await File(sourcePath).readAsString());
    }
    final source = combinedSources.toString();

    expect(source, contains('ProfileNavigationService'));
    expect(source, contains('ReportUserNavigationService'));
    expect(source, contains('openCv()'));
    expect(source, isNot(contains('Get.to(() => SocialProfile')));
    expect(source, isNot(contains('Get.to(() => ReportUser')));
    expect(source, isNot(contains('Get.to(() => Cv')));
  });
}
