part of 'career_profile_controller.dart';

class CareerProfileController extends GetxController {
  static CareerProfileController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CareerProfileController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static CareerProfileController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<CareerProfileController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CareerProfileController>(tag: tag);
  }

  final CvRepository _cvRepository = CvRepository.ensure();
  final cvVar = false.obs;
  final isFindingJob = false.obs;
  final isLoading = false.obs;
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  final fullName = ''.obs;
  final about = ''.obs;
  final meslek = ''.obs;
  final photoUrl = ''.obs;
  final RxList<CVLanguegeModel> languages = <CVLanguegeModel>[].obs;
  final RxList<CVExperinceModel> experiences = <CVExperinceModel>[].obs;
  final RxList<CvSchoolModel> schools = <CvSchoolModel>[].obs;
  final RxList<String> skills = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _handleCareerProfileInit();
  }
}
