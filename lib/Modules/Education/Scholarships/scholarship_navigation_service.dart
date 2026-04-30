import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Ads/admob_intersitital.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Applications/applications_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipApplicationsContent/applicant_profile.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/scholarship_preview_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/DormitoryInfo/dormitory_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/EducationInfo/education_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/FamilyInfo/family_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/MyScholarship/my_scholarship_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/PersonelInfo/personel_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Personalized/personalized_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/SavedItems/saved_items_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipDetail/scholarship_detail_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarships_view.dart';

class ScholarshipNavigationService {
  ScholarshipNavigationService._();

  static const String _cooldownPrefsKey =
      'scholarship_detail_interstitial_last_shown_at_ms';
  static const Duration _interstitialCooldown = Duration(minutes: 30);

  static Future<void> openDetail(
    Map<String, dynamic> scholarshipData,
  ) async {
    final preferences = ensureLocalPreferenceRepository();
    final now = DateTime.now();
    final lastShownAtMs = await preferences.getInt(_cooldownPrefsKey);
    final shouldAttemptInterstitial = lastShownAtMs == null ||
        now.difference(
              DateTime.fromMillisecondsSinceEpoch(lastShownAtMs),
            ) >=
            _interstitialCooldown;

    if (shouldAttemptInterstitial) {
      final didShowInterstitial = await showUnskippableInterstitialAd();
      if (didShowInterstitial) {
        await preferences.setInt(
          _cooldownPrefsKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    }

    await openDetailRoute(scholarshipData);
  }

  static Future<void> openDetailRoute(
    Map<String, dynamic> scholarshipData,
  ) async {
    await Get.to(
      () => ScholarshipDetailView(),
      arguments: scholarshipData,
    );
  }

  static Future<void> openApplications() async {
    await Get.to(() => ApplicationsView());
  }

  static Future<void> openApplicantProfile(String userId) async {
    await Get.to(() => ApplicantProfile(userID: userId));
  }

  static Future<void> openSavedItems() async {
    await Get.to(() => SavedItemsView());
  }

  static Future<void> openPersonalized() async {
    await Get.to(PersonalizedView());
  }

  static Future<void> openCreate({bool resetController = false}) async {
    if (resetController) {
      Get.delete<CreateScholarshipController>(force: true);
    }
    await Get.to(CreateScholarshipView());
  }

  static Future<void> openEdit(Map<String, dynamic> scholarshipData) async {
    Get.delete<CreateScholarshipController>(force: true);
    await Get.to(
      () => CreateScholarshipView(),
      arguments: {
        'scholarshipData': scholarshipData,
        'scholarshipId': scholarshipData['docId'],
      },
    );
  }

  static Future<void> openMyScholarships() async {
    await Get.to(MyScholarshipView());
  }

  static Future<void> openScholarshipsHome() async {
    await Get.to(() => ScholarshipsView());
  }

  static Future<void> openCreatePreview(String controllerTag) async {
    await Get.to(() => ScholarshipPreviewView(controllerTag: controllerTag));
  }

  static Future<void> openPersonalInfo() async {
    await Get.to(() => PersonelInfoView());
  }

  static Future<void> openEducationInfo() async {
    await Get.to(() => EducationInfoView());
  }

  static Future<void> openFamilyInfo() async {
    await Get.to(() => FamilyInfoView());
  }

  static Future<void> openDormitoryInfo() async {
    await Get.to(() => DormitoryInfoView());
  }
}
