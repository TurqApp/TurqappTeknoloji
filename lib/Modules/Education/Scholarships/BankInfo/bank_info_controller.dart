import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Services/current_user_service.dart';

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

  String localizedFastType(String value) {
    switch (value) {
      case _selectBank:
        return 'bank_info.select_bank'.tr;
      case _email:
        return 'bank_info.fast_email'.tr;
      case _phone:
        return 'bank_info.fast_phone'.tr;
      case _ibanType:
        return 'bank_info.fast_iban'.tr;
      default:
        return value;
    }
  }

  Future<void> loadData() async {
    try {
      final data = await _userRepository.getUserRaw(
            CurrentUserService.instance.effectiveUserId,
          ) ??
          const <String, dynamic>{};
      final bank = userString(data, key: "bank", scope: "finance");
      final iban = userString(data, key: "iban", scope: "finance");
      final kolayAdresFromDb = userString(
        data,
        key: "kolayAdresSelection",
        scope: "preferences",
        fallback: _email,
      );
      selectedBank.value = bank.isNotEmpty ? bank : _selectBank;
      this.iban.text = iban.startsWith("TR") ? iban.substring(2) : iban;
      kolayAdres.value =
          kolayAdresList.contains(kolayAdresFromDb) ? kolayAdresFromDb : _email;
    } catch (e) {
      AppSnackbar('common.error'.tr, 'bank_info.load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void showBankBottomSheet(BuildContext context) {
    ListBottomSheet.show(
      context: context,
      items: banks,
      title: 'bank_info.select_bank'.tr,
      selectedItem:
          selectedBank.value == _selectBank ? null : selectedBank.value,
      onSelect: (item) {
        selectedBank.value = item;
      },
    );
  }

  void showKolayAdresBottomSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      items: kolayAdresList.map(localizedFastType).toList(),
      title: 'bank_info.select_fast_type'.tr,
      selectedItem: localizedFastType(kolayAdres.value),
      onSelect: (item) {
        final selectedIndex =
            kolayAdresList.map(localizedFastType).toList().indexOf(item);
        kolayAdres.value =
            selectedIndex >= 0 ? kolayAdresList[selectedIndex] : item;
        iban.text = ''; // Clear the TextField when kolayAdres changes
      },
    );
  }

  Future<void> pasteFromClipboard() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null) {
      // Remove spaces and "TR" prefix for IBAN
      String cleanedText = data.text!.replaceAll(' ', '');
      if (kolayAdres.value == _ibanType && cleanedText.startsWith("TR")) {
        cleanedText = cleanedText.substring(2);
      }
      iban.text = cleanedText;
    }
  }

  void saveData() {
    if (iban.text.isEmpty) {
      AppSnackbar('common.warning'.tr, 'bank_info.missing_value'.tr);
      return;
    }
    if (selectedBank.value == _selectBank) {
      AppSnackbar('common.warning'.tr, 'bank_info.missing_bank'.tr);
      return;
    }
    if (kolayAdres.value == _email &&
        !RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(iban.text)) {
      AppSnackbar('common.error'.tr, 'bank_info.invalid_email'.tr);
      return;
    }

    // Save to Firestore
    _userRepository
        .updateUserFields(CurrentUserService.instance.effectiveUserId, {
      ...scopedUserUpdate(
        scope: 'finance',
        values: {
          "iban": kolayAdres.value == _ibanType ? "TR${iban.text}" : iban.text,
          "bank": selectedBank.value,
        },
      ),
      ...scopedUserUpdate(
        scope: 'preferences',
        values: {
          "kolayAdresSelection": kolayAdres.value,
        },
      ),
    }).then((_) {
      Get.back();
      AppSnackbar('common.success'.tr, 'bank_info.saved'.tr);
    }).catchError((e) {
      AppSnackbar('common.error'.tr, 'bank_info.save_failed'.tr);
    });
  }
}
