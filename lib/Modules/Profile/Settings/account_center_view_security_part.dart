part of 'account_center_view.dart';

class _SessionSecuritySection extends StatelessWidget {
  const _SessionSecuritySection({
    required this.accountCenter,
  });

  final AccountCenterService accountCenter;

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  Widget build(BuildContext context) {
    final uid = _currentUid;
    if (uid.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(
            'account_center.security'.tr,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontFamily: 'MontserratBold',
            ),
          ),
        ),
        _buildAccountCenterCard(
          child: StreamBuilder<Map<String, dynamic>?>(
            stream: UserRepository.ensure().watchUserRaw(uid),
            builder: (context, snapshot) {
              final enabled =
                  (snapshot.data?['singleDeviceSessionEnabled'] ?? false) ==
                      true;
              return SwitchListTile.adaptive(
                key: const ValueKey<String>(
                  IntegrationTestKeys.actionAccountCenterSingleDeviceToggle,
                ),
                value: enabled,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                onChanged: (value) async {
                  await accountCenter.setSingleDeviceSessionEnabled(value);
                  AppSnackbar(
                    'settings.account_center'.tr,
                    value
                        ? 'account_center.single_device_enabled'.tr
                        : 'account_center.single_device_disabled'.tr,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
