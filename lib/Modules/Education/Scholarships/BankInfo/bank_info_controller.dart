import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'bank_info_controller_actions_part.dart';
part 'bank_info_controller_data_part.dart';
part 'bank_info_controller_facade_part.dart';
part 'bank_info_controller_fields_part.dart';
part 'bank_info_controller_support_part.dart';
part 'bank_info_controller_ui_part.dart';

class BankInfoController extends GetxController {
  static BankInfoController ensure({
    required String tag,
    bool permanent = false,
  }) =>
      _ensureBankInfoController(tag: tag, permanent: permanent);

  static BankInfoController? maybeFind({required String tag}) =>
      _maybeFindBankInfoController(tag: tag);

  static const String _selectBank = "Banka Seç";
  static const String _email = "E-Posta";
  static const String _phone = "Telefon";
  static const String _ibanType = "IBAN";
  final _state = _BankInfoControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleBankInfoControllerInit(this);
  }
}
