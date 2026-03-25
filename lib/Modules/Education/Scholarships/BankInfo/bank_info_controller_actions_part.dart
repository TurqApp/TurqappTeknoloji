part of 'bank_info_controller.dart';

extension _BankInfoControllerActionsX on BankInfoController {
  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data == null) return;
    var cleanedText = data.text!.replaceAll(' ', '');
    if (kolayAdres.value == BankInfoController._ibanType &&
        cleanedText.startsWith('TR')) {
      cleanedText = cleanedText.substring(2);
    }
    iban.text = cleanedText;
  }

  void saveData() {
    if (iban.text.isEmpty) {
      AppSnackbar('common.warning'.tr, 'bank_info.missing_value'.tr);
      return;
    }
    if (selectedBank.value == BankInfoController._selectBank) {
      AppSnackbar('common.warning'.tr, 'bank_info.missing_bank'.tr);
      return;
    }
    if (kolayAdres.value == BankInfoController._email &&
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(iban.text)) {
      AppSnackbar('common.error'.tr, 'bank_info.invalid_email'.tr);
      return;
    }

    _userRepository
        .updateUserFields(CurrentUserService.instance.effectiveUserId, {
      ...scopedUserUpdate(
        scope: 'finance',
        values: {
          'iban': kolayAdres.value == BankInfoController._ibanType
              ? 'TR${iban.text}'
              : iban.text,
          'bank': selectedBank.value,
        },
      ),
      ...scopedUserUpdate(
        scope: 'preferences',
        values: {
          'kolayAdresSelection': kolayAdres.value,
        },
      ),
    }).then((_) {
      Get.back();
      AppSnackbar('common.success'.tr, 'bank_info.saved'.tr);
    }).catchError((_) {
      AppSnackbar('common.error'.tr, 'bank_info.save_failed'.tr);
    });
  }
}
