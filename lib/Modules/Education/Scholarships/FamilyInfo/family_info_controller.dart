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
part 'family_info_controller_runtime_part.dart';

class FamilyInfoController extends GetxController {
  static FamilyInfoController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(FamilyInfoController(), tag: tag, permanent: permanent);
  }

  static FamilyInfoController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<FamilyInfoController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<FamilyInfoController>(tag: tag);
  }

  static const String _selectValue = "Seçiniz";
  static const String _selectHomeOwnership = "Seçim Yap";
  static const String _selectJob = "Meslek Seç";
  static const String _yesValue = "Evet";
  static const String _noValue = "Hayır";
  static const String _ownedHome = "Kendinize Ait Ev";
  static const String _relativeHome = "Yakınınıza Ait Ev";
  static const String _lodgingHome = "Lojman";
  static const String _rentHome = "Kira";
  final UserRepository _userRepository = UserRepository.ensure();
  final CityDirectoryService _cityDirectoryService =
      CityDirectoryService.ensure();
  final isLoading = true.obs;
  final familyInfo = ''.obs;

  final fatherName = TextEditingController().obs;
  final fatherSurname = TextEditingController().obs;
  final fatherSalary = TextEditingController().obs;
  final fatherPhoneNumber = TextEditingController().obs;
  final fatherLiving = _selectValue.obs;
  final fatherJob = _selectJob.obs;
  final motherName = TextEditingController().obs;
  final motherSurname = TextEditingController().obs;
  final motherSalary = TextEditingController().obs;
  final motherPhoneNumber = TextEditingController().obs;
  final motherLiving = _selectValue.obs;
  final motherJob = _selectJob.obs;
  final totalLiving = TextEditingController().obs;
  final evMulkiyeti = _selectHomeOwnership.obs;
  final city = "".obs;
  final town = "".obs;
  final ScrollController scrollController = ScrollController();

  final evevMulkiyeti =
      [_ownedHome, _relativeHome, _lodgingHome, _rentHome].obs;
  final living = [_yesValue, _noValue].obs;
  final sehirler = <String>[].obs;
  final sehirlerVeIlcelerData = <CitiesModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }
}
