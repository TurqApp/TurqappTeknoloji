import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scholarship detail opens use navigation service without behavior drift',
      () async {
    final serviceSource = await File(
      'lib/Modules/Education/Scholarships/scholarship_navigation_service.dart',
    ).readAsString();
    final ctaSource = await File(
      'lib/Core/Services/education_feed_cta_navigation_service.dart',
    ).readAsString();
    final personalizedViewSource = await File(
      'lib/Modules/Education/Scholarships/Personalized/personalized_view.dart',
    ).readAsString();
    final personalizedContentSource = await File(
      'lib/Modules/Education/Scholarships/Personalized/'
      'personalized_content.dart',
    ).readAsString();

    expect(serviceSource, contains('openDetailRoute'));
    expect(serviceSource, contains('showUnskippableInterstitialAd'));
    expect(ctaSource, contains('ScholarshipNavigationService.openDetailRoute'));
    expect(
      personalizedViewSource,
      contains('ScholarshipNavigationService.openDetailRoute'),
    );
    expect(
      personalizedContentSource,
      contains('ScholarshipNavigationService.openDetailRoute'),
    );
    expect(ctaSource, isNot(contains('() => ScholarshipDetailView()')));
    expect(
      personalizedViewSource,
      isNot(contains('() => ScholarshipDetailView()')),
    );
    expect(
      personalizedContentSource,
      isNot(contains('() => ScholarshipDetailView()')),
    );
  });

  test('scholarship entry opens stay behind navigation service', () async {
    final serviceSource = await File(
      'lib/Modules/Education/Scholarships/scholarship_navigation_service.dart',
    ).readAsString();
    final educationSource = await File(
      'lib/Modules/Education/education_view_actions_part.dart',
    ).readAsString();
    final scholarshipActionsSource = await File(
      'lib/Modules/Education/Scholarships/scholarships_view_actions_part.dart',
    ).readAsString();
    final scholarshipControllerSource = await File(
      'lib/Modules/Education/Scholarships/'
      'scholarships_controller_actions_part.dart',
    ).readAsString();
    final createControllerFormSource = await File(
      'lib/Modules/Education/Scholarships/CreateScholarship/'
      'create_scholarship_controller_form_part.dart',
    ).readAsString();
    final createControllerSubmitSource = await File(
      'lib/Modules/Education/Scholarships/CreateScholarship/'
      'create_scholarship_controller_submission_part.dart',
    ).readAsString();
    final createBasicSource = await File(
      'lib/Modules/Education/Scholarships/CreateScholarship/'
      'create_scholarship_basic_part.dart',
    ).readAsString();
    final detailSource = await File(
      'lib/Modules/Education/Scholarships/ScholarshipDetail/'
      'scholarship_detail_view_actions_part.dart',
    ).readAsString();
    final applicationContentSource = await File(
      'lib/Modules/Education/Scholarships/ScholarshipApplicationsContent/'
      'scholarship_applications_content.dart',
    ).readAsString();

    for (final method in <String>[
      'openApplications',
      'openApplicantProfile',
      'openSavedItems',
      'openPersonalized',
      'openCreate',
      'openEdit',
      'openMyScholarships',
      'openScholarshipsHome',
      'openCreatePreview',
      'openPersonalInfo',
      'openEducationInfo',
      'openFamilyInfo',
      'openDormitoryInfo',
    ]) {
      expect(serviceSource, contains(method));
    }

    expect(educationSource, contains('openApplications'));
    expect(educationSource, contains('openCreate('));
    expect(educationSource, contains('openMyScholarships'));
    expect(educationSource, contains('openSavedItems'));
    expect(educationSource, contains('openPersonalized'));
    expect(scholarshipActionsSource, contains('openCreate('));
    expect(scholarshipActionsSource, contains('openMyScholarships'));
    expect(scholarshipActionsSource, contains('openSavedItems'));
    expect(scholarshipActionsSource, contains('openApplications'));
    expect(scholarshipActionsSource, contains('openPersonalized'));
    expect(scholarshipControllerSource, contains('openPersonalInfo'));
    expect(scholarshipControllerSource, contains('openEducationInfo'));
    expect(scholarshipControllerSource, contains('openFamilyInfo'));
    expect(scholarshipControllerSource, contains('openDormitoryInfo'));
    expect(createControllerFormSource, contains('openCreatePreview(tag)'));
    expect(createControllerSubmitSource, contains('openScholarshipsHome()'));
    expect(createBasicSource, contains('openScholarshipsHome'));
    expect(detailSource, contains('openEdit('));
    expect(applicationContentSource, contains('openApplicantProfile(userID)'));
  });

  test('feature code does not open scholarship routes directly', () async {
    const approvedFiles = <String>{
      'lib/Modules/Education/Scholarships/scholarship_navigation_service.dart',
    };
    final directRouteTokens = <String>[
      '=> ApplicationsView(',
      'Get.to(() => ApplicationsView',
      '=> ApplicantProfile(',
      'Get.to(() => ApplicantProfile',
      '=> SavedItemsView(',
      'Get.to(() => SavedItemsView',
      '=> PersonalizedView(',
      'Get.to(PersonalizedView',
      '=> CreateScholarshipView(',
      'Get.to(CreateScholarshipView',
      '=> MyScholarshipView(',
      'Get.to(MyScholarshipView',
      '=> ScholarshipsView(',
      'Get.to(() => ScholarshipsView',
      'Get.to(ScholarshipsView',
      '=> ScholarshipPreviewView(',
      'Get.to(() => ScholarshipPreviewView',
      '=> PersonelInfoView(',
      'Get.to(() => PersonelInfoView',
      '=> EducationInfoView(',
      'Get.to(() => EducationInfoView',
      '=> FamilyInfoView(',
      'Get.to(() => FamilyInfoView',
      '=> DormitoryInfoView(',
      'Get.to(() => DormitoryInfoView',
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
      if (!directRouteTokens.any(source.contains)) continue;
      violations.add(normalizedPath);
    }

    expect(
      violations,
      isEmpty,
      reason: 'Scholarship route creation should stay behind '
          'ScholarshipNavigationService.',
    );
  });
}
