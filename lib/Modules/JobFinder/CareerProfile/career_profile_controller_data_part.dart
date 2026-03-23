part of 'career_profile_controller.dart';

extension CareerProfileControllerDataPart on CareerProfileController {
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
}
