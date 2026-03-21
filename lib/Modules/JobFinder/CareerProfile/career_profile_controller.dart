import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/CVModels/school_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class CareerProfileController extends GetxController {
  final CvRepository _cvRepository = CvRepository.ensure();
  var cvVar = false.obs;
  var isFindingJob = false.obs;
  var isLoading = false.obs;
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  // CV summary fields
  var fullName = ''.obs;
  var about = ''.obs;
  var meslek = ''.obs;
  var photoUrl = ''.obs;
  RxList<CVLanguegeModel> languages = <CVLanguegeModel>[].obs;
  RxList<CVExperinceModel> experiences = <CVExperinceModel>[].obs;
  RxList<CvSchoolModel> schools = <CvSchoolModel>[].obs;
  RxList<String> skills = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapCvData());
  }

  Future<void> _bootstrapCvData() async {
    final uid = CurrentUserService.instance.userId;
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
        minInterval: _silentRefreshInterval,
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
      final uid = CurrentUserService.instance.userId;
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
      final uid = CurrentUserService.instance.userId;
      if (uid.isEmpty) return;
      await FirebaseFirestore.instance
          .collection('CV')
          .doc(uid)
          .update({'findingJob': isFindingJob.value});
      final current = await _cvRepository.getCv(uid, preferCache: true);
      if (current != null) {
        current['findingJob'] = isFindingJob.value;
        await _cvRepository.setCv(uid, current);
      } else {
        await _cvRepository.invalidate(uid);
      }
    } catch (_) {
      isFindingJob.value = !isFindingJob.value;
    }
  }
}
