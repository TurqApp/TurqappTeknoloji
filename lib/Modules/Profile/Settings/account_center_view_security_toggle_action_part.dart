part of 'account_center_view.dart';

extension AccountCenterViewSecurityToggleActionPart on _SessionSecuritySection {
  Future<void> _handleSecurityToggleChanged(bool value) async {
    await accountCenter.setSingleDeviceSessionEnabled(value);
    AppSnackbar(
      'settings.account_center'.tr,
      value
          ? 'account_center.single_device_enabled'.tr
          : 'account_center.single_device_disabled'.tr,
    );
  }
}
