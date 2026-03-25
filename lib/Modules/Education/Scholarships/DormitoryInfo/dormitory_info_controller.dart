import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/education_reference_data_service.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Models/Education/dormitory_model.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'dormitory_info_controller_labels_part.dart';
part 'dormitory_info_controller_data_part.dart';
part 'dormitory_info_controller_actions_part.dart';

class DormitoryInfoController extends GetxController {
  static DormitoryInfoController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(DormitoryInfoController(), tag: tag, permanent: permanent);
  }

  static DormitoryInfoController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<DormitoryInfoController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<DormitoryInfoController>(tag: tag);
  }

  static const String _selectCity = "Şehir Seç";
  static const String _selectDistrict = "İlçe Seç";
  static const String _selectAdminType = "İdari Seç";
  static const String _publicAdminType = "DEVLET";
  static const String _privateAdminType = "ÖZEL";
  String get selectCityValue => _selectCity;
  String get selectDistrictValue => _selectDistrict;
  String get selectAdminTypeValue => _selectAdminType;
  final UserRepository _userRepository = UserRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final EducationReferenceDataService _referenceDataService =
      EducationReferenceDataService.ensure();
  final isLoading = true.obs;
  final sehir = _selectCity.obs;
  final ilce = _selectDistrict.obs;
  final yurt = "".obs;
  final sub = _selectAdminType.obs;
  final listedeYok = false.obs;
  final yurtInput = TextEditingController();
  final yurtSelectionController = TextEditingController();
  final yurtInputText = "".obs;
  final subList = [_publicAdminType, _privateAdminType].obs;
  final sehirler = <String>[].obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;
  final yurtList = <DormitoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
    ever(yurt, (_) {
      yurtSelectionController.text = yurt.value;
    });
    yurtInput.addListener(() {
      yurtInputText.value = yurtInput.text;
    });
  }

  bool get isCityUnselected =>
      sehir.value.isEmpty || sehir.value == _selectCity;

  @override
  void onClose() {
    yurtInput.dispose();
    yurtSelectionController.dispose();
    super.onClose();
  }
}
