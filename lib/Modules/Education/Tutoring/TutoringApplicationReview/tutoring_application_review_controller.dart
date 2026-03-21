import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/tutoring_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/tutoring_application_model.dart';

class TutoringApplicationReviewController extends GetxController {
  static TutoringApplicationReviewController ensure({
    required String tutoringDocID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TutoringApplicationReviewController(tutoringDocID: tutoringDocID),
      tag: tag,
      permanent: permanent,
    );
  }

  static TutoringApplicationReviewController? maybeFind({String? tag}) {
    if (!Get.isRegistered<TutoringApplicationReviewController>(tag: tag)) {
      return null;
    }
    return Get.find<TutoringApplicationReviewController>(tag: tag);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();
  final String tutoringDocID;
  TutoringApplicationReviewController({required this.tutoringDocID});

  RxList<TutoringApplicationModel> applicants =
      <TutoringApplicationModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadApplicants();
  }

  Future<void> loadApplicants() async {
    isLoading.value = true;
    try {
      applicants.value = await _tutoringRepository.fetchApplications(
        tutoringDocID,
        preferCache: true,
      );
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getApplicantProfile(String userID) async {
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      return summary?.toMap();
    } catch (_) {}
    return null;
  }

  Future<void> updateStatus(String userID, String newStatus) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _tutoringRepository.updateApplicationStatus(
        tutoringId: tutoringDocID,
        userId: userID,
        status: newStatus,
      );

      final index = applicants.indexWhere((a) => a.userID == userID);
      if (index != -1) {
        final old = applicants[index];
        applicants[index] = TutoringApplicationModel(
          tutoringDocID: old.tutoringDocID,
          userID: old.userID,
          tutoringTitle: old.tutoringTitle,
          tutorName: old.tutorName,
          tutorImage: old.tutorImage,
          status: newStatus,
          timeStamp: old.timeStamp,
          statusUpdatedAt: now,
          note: old.note,
        );
        applicants.refresh();
      }
    } catch (_) {}
  }
}
