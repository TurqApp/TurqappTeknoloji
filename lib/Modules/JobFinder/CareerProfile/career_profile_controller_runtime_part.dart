part of 'career_profile_controller.dart';

CareerProfileController ensureCareerProfileController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindCareerProfileController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    CareerProfileController(),
    tag: tag,
    permanent: permanent,
  );
}

CareerProfileController? maybeFindCareerProfileController({String? tag}) {
  final isRegistered = Get.isRegistered<CareerProfileController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<CareerProfileController>(tag: tag);
}

class CareerProfileController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _state = _CareerProfileControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleCareerProfileInit();
  }
}

extension CareerProfileControllerRuntimePart on CareerProfileController {
  void _handleCareerProfileInit() {
    unawaited(_bootstrapCvData());
  }

  Future<void> _bootstrapCvData() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      isLoading.value = false;
      return;
    }

    final cached = await _cvRepository.getCv(
      uid,
      preferCache: true,
      cacheOnly: true,
    );
    if (cached != null) {
      _applyCv(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'jobs:career_profile:$uid',
        minInterval: CareerProfileController._silentRefreshInterval,
      )) {
        unawaited(loadCvData(silent: true, forceRefresh: true));
      }
      return;
    }

    await loadCvData();
  }

  Future<void> loadCvData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent) {
      isLoading.value = true;
    }
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;
      final data = await _cvRepository.getCv(
        uid,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );

      if (data != null) {
        _applyCv(data);
        SilentRefreshGate.markRefreshed('jobs:career_profile:$uid');
      } else {
        cvVar.value = false;
        fullName.value = '';
        about.value = '';
        photoUrl.value = '';
        isFindingJob.value = false;
        schools.clear();
        languages.clear();
        experiences.clear();
        skills.clear();
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void _applyCv(Map<String, dynamic> data) {
    cvVar.value = true;
    fullName.value =
        '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
    about.value = data['about'] ?? '';
    photoUrl.value = (data['photoUrl'] ?? '').toString().trim();
    isFindingJob.value = data['findingJob'] ?? false;

    schools.value = (data['okullar'] as List<dynamic>? ?? [])
        .map((e) => CvSchoolModel.fromMap(e as Map<String, dynamic>))
        .toList(growable: false);

    languages.value = (data['diller'] as List<dynamic>? ?? [])
        .map((e) => CVLanguegeModel.fromMap(e as Map<String, dynamic>))
        .toList(growable: false);

    experiences.value = (data['deneyim'] as List<dynamic>? ?? [])
        .map((e) => CVExperinceModel.fromMap(e as Map<String, dynamic>))
        .toList(growable: false);

    skills.value = (data['skills'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(growable: false);
  }

  Future<void> toggleFindingJob() async {
    try {
      isFindingJob.value = !isFindingJob.value;
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;
      await _cvRepository
          .updateCvFields(uid, {'findingJob': isFindingJob.value});
    } catch (_) {
      isFindingJob.value = !isFindingJob.value;
    }
  }
}
