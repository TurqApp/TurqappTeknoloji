import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/education_reference_data_service.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Models/Education/high_school_model.dart';
import 'package:turqappv2/Models/Education/higher_education_model.dart';
import 'package:turqappv2/Models/middle_school_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'education_info_controller_data_part.dart';
part 'education_info_controller_actions_part.dart';
part 'education_info_controller_facade_part.dart';
part 'education_info_controller_labels_part.dart';
part 'education_info_controller_lifecycle_part.dart';

class EducationInfoController extends GetxController
    with GetTickerProviderStateMixin {
  static EducationInfoController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(EducationInfoController(), tag: tag, permanent: permanent);
  }

  static EducationInfoController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<EducationInfoController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<EducationInfoController>(tag: tag);
  }

  static const String _middleSchool = 'Ortaokul';
  static const String _highSchool = 'Lise';
  static const String _associate = 'Önlisans';
  static const String _bachelor = 'Lisans';
  static const String _masters = 'Yüksek Lisans';
  static const String _doctorate = 'Doktora';
  final UserRepository _userRepository = UserRepository.ensure();
  final CurrentUserService _currentUserService = CurrentUserService.instance;
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final EducationReferenceDataService _referenceDataService =
      EducationReferenceDataService.ensure();
  RxString selectedEducationLevel = ''.obs;
  RxString content = ''.obs;
  RxBool isLoading = false.obs;
  RxBool isInitialLoading = true.obs;

  RxString selectedCountry = ''.obs;
  RxString selectedCity = ''.obs;
  RxString selectedDistrict = ''.obs;
  RxString selectedSchool = ''.obs;
  RxString selectedHighSchool = ''.obs;
  RxString selectedUniversity = ''.obs;
  RxString selectedFaculty = ''.obs;
  RxString selectedDepartment = ''.obs;
  RxString selectedClassLevel = ''.obs;
  RxList<String> countries = <String>[].obs;
  RxList<String> cities = <String>[].obs;
  RxList<CitiesModel> cityDistrictData = <CitiesModel>[].obs;
  RxList<MiddleSchoolModel> middleSchools = <MiddleSchoolModel>[].obs;
  RxList<HighSchoolModel> highSchools = <HighSchoolModel>[].obs;
  RxList<HigherEducationModel> higherEducations = <HigherEducationModel>[].obs;

  RxBool hasMiddleSchoolData = false.obs;
  RxBool hasHighSchoolData = false.obs;
  RxBool hasHigherEducationData = false.obs;

  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, RxDouble> _animationTurns = {};

  @override
  void onInit() {
    super.onInit();
    _EducationInfoControllerLifecyclePart(this).handleOnInit();
  }

  @override
  void onClose() {
    _EducationInfoControllerLifecyclePart(this).handleOnClose();
    super.onClose();
  }
}
