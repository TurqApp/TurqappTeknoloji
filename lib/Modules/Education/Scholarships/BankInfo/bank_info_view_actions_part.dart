part of 'bank_info_view.dart';

extension _BankInfoViewActionsPart on _BankInfoViewState {
  Future<void> _showResetConfirmation() async {
    noYesAlert(
      title: 'bank_info.reset_title'.tr,
      message: 'bank_info.reset_body'.tr,
      cancelText: 'common.cancel'.tr,
      yesText: 'common.reset'.tr,
      yesButtonColor: CupertinoColors.destructiveRed,
      onYesPressed: () async {
        controller.selectedBank.value = controller.defaultBankSelection;
        controller.kolayAdres.value = controller.defaultFastTypeEmail;
        controller.iban.clear();
        await _userRepository.updateUserFields(
          CurrentUserService.instance.effectiveUserId,
          {
            ...scopedUserUpdate(
              scope: 'finance',
              values: {
                'iban': '',
                'bank': '',
              },
            ),
            ...scopedUserUpdate(
              scope: 'preferences',
              values: {
                'kolayAdresSelection': '',
              },
            ),
          },
        );
        AppSnackbar(
          'common.success'.tr,
          'bank_info.reset_success'.tr,
        );
      },
    );
  }
}
