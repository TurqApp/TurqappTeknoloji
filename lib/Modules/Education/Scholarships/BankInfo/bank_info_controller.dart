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
part 'bank_info_controller_ui_part.dart';

class BankInfoController extends GetxController {
  static BankInfoController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(BankInfoController(), tag: tag, permanent: permanent);
  }

  static BankInfoController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<BankInfoController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<BankInfoController>(tag: tag);
  }

  static const String _selectBank = "Banka Seç";
  static const String _email = "E-Posta";
  static const String _phone = "Telefon";
  static const String _ibanType = "IBAN";
  final UserRepository _userRepository = UserRepository.ensure();
  // Reactive variables
  final RxInt color = 0xFF000000.obs;
  final RxString selectedBank = _selectBank.obs;
  final RxString kolayAdres = _email.obs;
  final RxBool isLoading = true.obs;
  final TextEditingController iban = TextEditingController();

  // Lists
  final List<String> kolayAdresList = [_email, _phone, _ibanType];
  final List<String> banks = [
    "Akbank",
    "Albaraka Türk Katılım Bankası",
    "Alternatifbank",
    "Anadolubank",
    "Arap Türk Bankası",
    "Citibank",
    "Denizbank",
    "Fibabank",
    "Hsbc Bank",
    "İng Bank",
    "Kuveyt Türk Katılım Bankası",
    "Odea Bank",
    "Qnb Finansbank",
    "Şekerbank",
    "Turkish Bank",
    "Türk Ekonomi Bankası",
    "Türk Ticaret Bankası",
    "Türkiye Emlak Katılım Bankası",
    "Türkiye Finans Katılım Bankası",
    "Türkiye Garanti Bankası",
    "Türkiye Halk Bankası",
    "Türkiye İş Bankası",
    "Türkiye Vakıflar Bankası",
    "Vakıf Katılım Bankası",
    "Yapı Ve Kredi Bankası",
    "Ziraat Bankası",
    "Ziraat Katılım Bankası",
  ];

  String get defaultBankSelection => _selectBank;
  String get defaultFastTypeEmail => _email;
  bool get isIbanSelected => kolayAdres.value == _ibanType;
  bool get isPhoneSelected => kolayAdres.value == _phone;
  bool get isEmailSelected => kolayAdres.value == _email;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  String localizedFastType(String value) =>
      _BankInfoControllerUiX(this).localizedFastType(value);

  Future<void> loadData() => _BankInfoControllerDataX(this).loadData();

  void showBankBottomSheet(BuildContext context) =>
      _BankInfoControllerUiX(this).showBankBottomSheet(context);

  void showKolayAdresBottomSheet(BuildContext context) =>
      _BankInfoControllerUiX(this).showKolayAdresBottomSheet(context);

  Future<void> pasteFromClipboard() =>
      _BankInfoControllerActionsX(this).pasteFromClipboard();

  void saveData() => _BankInfoControllerActionsX(this).saveData();
}
