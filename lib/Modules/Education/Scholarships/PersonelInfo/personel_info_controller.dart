import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'personel_info_controller_data_part.dart';
part 'personel_info_controller_fields_part.dart';
part 'personel_info_controller_labels_part.dart';
part 'personel_info_controller_form_part.dart';

class PersonelInfoController extends GetxController
    with GetTickerProviderStateMixin {
  static PersonelInfoController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(PersonelInfoController(), tag: tag, permanent: permanent);
  }

  static PersonelInfoController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<PersonelInfoController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PersonelInfoController>(tag: tag);
  }

  final UserRepository _userRepository = UserRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final _state = _PersonelInfoControllerState();

  String get defaultSelectValue => _selectValue;
  String get turkeyValue => _turkey;
  String get singleValue => _single;
  String get noneValue => _none;
  String get notWorkingValue => _notWorking;
  bool get isTurkeySelected => county.value == _turkey;

  @override
  void onInit() {
    super.onInit();
    loadCitiesAndTowns();
    fetchData();
    initializeFieldConfigs();
    initializeAnimationControllers();
  }

  @override
  void onClose() {
    disposeAnimationControllers();
    super.onClose();
  }
}
