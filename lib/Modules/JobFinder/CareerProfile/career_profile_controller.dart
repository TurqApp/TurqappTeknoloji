import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/CVModels/school_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'career_profile_controller_runtime_part.dart';

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
    _handleCareerProfileInit();
  }
}
