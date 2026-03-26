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
part 'dormitory_info_controller_fields_part.dart';
part 'dormitory_info_controller_support_part.dart';

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
  final _state = _DormitoryInfoControllerState(
    selectCityValue: _selectCity,
    selectDistrictValue: _selectDistrict,
    selectAdminTypeValue: _selectAdminType,
    adminTypes: const <String>[_publicAdminType, _privateAdminType],
  );

  @override
  void onInit() {
    super.onInit();
    _initializeDormitoryInfoController();
  }

  @override
  void onClose() {
    _disposeDormitoryInfoController();
    super.onClose();
  }
}
