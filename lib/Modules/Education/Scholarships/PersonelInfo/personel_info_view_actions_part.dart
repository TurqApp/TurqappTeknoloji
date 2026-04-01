part of 'personel_info_view.dart';

extension _PersonelInfoViewActionsPart on _PersonelInfoViewState {
  List<PullDownMenuEntry> _buildMenuItems() {
    return [
      PullDownMenuItem(
        title: 'personal_info.reset_menu'.tr,
        icon: CupertinoIcons.restart,
        onTap: _showResetConfirmation,
      ),
    ];
  }

  void _showResetConfirmation() {
    noYesAlert(
      title: 'personal_info.reset_title'.tr,
      message: 'personal_info.reset_body'.tr,
      cancelText: 'common.cancel'.tr,
      yesText: 'common.reset'.tr,
      onYesPressed: _resetAndReload,
    );
  }

  Future<void> _resetAndReload() async {
    controller.resetToOriginal();
    await _userRepository.updateUserFields(
      CurrentUserService.instance.effectiveUserId,
      {
        ...scopedUserUpdate(
          scope: 'family',
          values: {
            "engelliRaporu": controller.noneValue,
          },
        ),
        ...scopedUserUpdate(
          scope: 'profile',
          values: {
            "tc": "",
            "medeniHal": controller.singleValue,
            "ulke": controller.turkeyValue,
            "nufusSehir": "",
            "nufusIlce": "",
            "cinsiyet": controller.defaultSelectValue,
            "calismaDurumu": controller.notWorkingValue,
            "dogumTarihi": "",
          },
        ),
      },
    );
    await controller.fetchData();
    AppSnackbar(
      'common.success'.tr,
      'personal_info.reset_success'.tr,
    );
  }

  Future<void> _showBirthDatePicker(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return DatePickerBottomSheet(
          initialDate: controller.selectedDate.value,
          onSelected: (DateTime date) {
            controller.selectedDate.value = date;
          },
          title: 'personal_info.birth_date_title'.tr,
        );
      },
    );
  }
}
