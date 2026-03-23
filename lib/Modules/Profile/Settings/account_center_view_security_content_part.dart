part of 'account_center_view.dart';

extension AccountCenterViewSecurityContentPart on _SessionSecuritySection {
  Widget _buildSecurityContent(String uid) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: UserRepository.ensure().watchUserRaw(uid),
        builder: (context, snapshot) {
          final enabled =
              (snapshot.data?['singleDeviceSessionEnabled'] ?? false) == true;
          return SwitchListTile.adaptive(
            key: const ValueKey<String>(
              IntegrationTestKeys.actionAccountCenterSingleDeviceToggle,
            ),
            value: enabled,
            onChanged: (value) async {
              await accountCenter.setSingleDeviceSessionEnabled(value);
              AppSnackbar(
                'settings.account_center'.tr,
                value
                    ? 'account_center.single_device_enabled'.tr
                    : 'account_center.single_device_disabled'.tr,
              );
            },
            title: Text(
              'account_center.single_device_title'.tr,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'MontserratBold',
              ),
            ),
            subtitle: Text(
              'account_center.single_device_desc'.tr,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontFamily: 'MontserratMedium',
                height: 1.35,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          );
        },
      ),
    );
  }
}
