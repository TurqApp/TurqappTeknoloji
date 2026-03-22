part of 'dormitory_info_view.dart';

extension _DormitoryInfoViewActionsPart on _DormitoryInfoViewState {
  List<PullDownMenuEntry> _buildMenuItems() {
    return [
      PullDownMenuItem(
        title: 'dormitory.reset_menu'.tr,
        icon: CupertinoIcons.restart,
        onTap: _showResetConfirmation,
      ),
    ];
  }

  void _showResetConfirmation() {
    noYesAlert(
      title: 'dormitory.reset_title'.tr,
      message: 'dormitory.reset_body'.tr,
      cancelText: 'common.cancel'.tr,
      yesText: 'common.reset'.tr,
      yesButtonColor: CupertinoColors.destructiveRed,
      onYesPressed: _resetDormitoryInfo,
    );
  }

  Future<void> _resetDormitoryInfo() async {
    controller.yurt.value = '';
    controller.sehir.value = controller.selectCityValue;
    controller.ilce.value = controller.selectDistrictValue;
    controller.sub.value = controller.selectAdminTypeValue;
    controller.listedeYok.value = false;
    controller.yurtInput.clear();
    controller.yurtInputText.value = '';
    controller.yurtSelectionController.clear();

    await _userRepository.updateUserFields(
      CurrentUserService.instance.effectiveUserId,
      scopedUserUpdate(
        scope: 'family',
        values: {'yurt': ''},
      ),
    );

    AppSnackbar(
      'common.success'.tr,
      'dormitory.reset_success'.tr,
    );
  }
}
