import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Models/cities_model.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/city_directory_service.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'family_info_controller_data_part.dart';
part 'family_info_controller_actions_part.dart';
part 'family_info_controller_facade_part.dart';
part 'family_info_controller_fields_part.dart';
part 'family_info_controller_runtime_part.dart';

class FamilyInfoController extends GetxController {
  static FamilyInfoController ensure({
    required String tag,
    bool permanent = false,
  }) =>
      _ensureFamilyInfoController(tag: tag, permanent: permanent);

  static FamilyInfoController? maybeFind({required String tag}) =>
      _maybeFindFamilyInfoController(tag: tag);

  static const String _selectValue = "Seçiniz";
  static const String _selectHomeOwnership = "Seçim Yap";
  static const String _selectJob = "Meslek Seç";
  static const String _yesValue = "Evet";
  static const String _noValue = "Hayır";
  static const String _ownedHome = "Kendinize Ait Ev";
  static const String _relativeHome = "Yakınınıza Ait Ev";
  static const String _lodgingHome = "Lojman";
  static const String _rentHome = "Kira";
  final _state = _FamilyInfoControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleFamilyInfoControllerInit(this);
  }
}
