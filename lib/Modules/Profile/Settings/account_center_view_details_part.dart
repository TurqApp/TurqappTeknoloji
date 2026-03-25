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

class _ContactDetailsView extends StatelessWidget {
  const _ContactDetailsView();

  @override
  Widget build(BuildContext context) {
    final currentUserService = CurrentUserService.instance;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'account_center.contact_details'.tr),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  final email = currentUserService.email.trim();
                  final phone = currentUserService.phoneNumber.trim();
                  final emailVerified = currentUserService.isEmailVerified;
                  final phoneVerified = phone.isNotEmpty;
                  return _buildAccountCenterCard(
                    child: Column(
                      children: [
                        _ContactStatusRow(
                          icon: CupertinoIcons.mail,
                          title: 'account_center.email'.tr,
                          value: email.isNotEmpty
                              ? email
                              : 'account_center.email_missing'.tr,
                          isVerified: emailVerified,
                          verifiedLabel: 'account_center.verified'.tr,
                          pendingLabel: 'account_center.verify'.tr,
                          onTap: () => Get.to(() => EditorEmail()),
                        ),
                        const Divider(
                          height: 1,
                          indent: 18,
                          endIndent: 18,
                        ),
                        _ContactStatusRow(
                          icon: CupertinoIcons.phone,
                          title: 'account_center.phone'.tr,
                          value: phone.isNotEmpty
                              ? phone
                              : 'account_center.phone_missing'.tr,
                          isVerified: phoneVerified,
                          verifiedLabel: 'account_center.verified'.tr,
                          pendingLabel: 'account_center.unverified'.tr,
                          onTap: () => Get.to(() => EditorPhoneNumber()),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactStatusRow extends StatelessWidget {
  const _ContactStatusRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.isVerified,
    required this.verifiedLabel,
    required this.pendingLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isVerified;
  final String verifiedLabel;
  final String pendingLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = isVerified ? Colors.green : Colors.blueAccent;
    final statusText = isVerified ? verifiedLabel : pendingLabel;

    return _buildAccountCenterRowShell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAccountCenterInfoContent(
                title: title,
                value: value,
              ),
            ),
            if (!isVerified)
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 14,
                  fontFamily: 'MontserratMedium',
                ),
              )
            else
              Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PersonalDetailsSection extends StatelessWidget {
  const _PersonalDetailsSection({
    required this.currentUserService,
    required this.userRepository,
    required this.onContactTap,
  });

  final CurrentUserService currentUserService;
  final UserRepository userRepository;
  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    final currentUid = currentUserService.effectiveUserId;
    return FutureBuilder<String?>(
      key: ValueKey(currentUid),
      future: _loadPersonalContactDetails(
        currentUserService: currentUserService,
        userRepository: userRepository,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !(snapshot.hasData && (snapshot.data?.isNotEmpty ?? false))) {
          return _buildAccountCenterCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: const CupertinoActivityIndicator(),
          );
        }

        return _PersonalDetailsCard(
          contactDetails: snapshot.data,
          onContactTap: onContactTap,
        );
      },
    );
  }
}

Future<String?> _loadPersonalContactDetails({
  required CurrentUserService currentUserService,
  required UserRepository userRepository,
}) async {
  final current = currentUserService.currentUser;
  final parts = <String>[];

  final directEmail = (current?.email ?? currentUserService.email).trim();
  final directPhone =
      (current?.phoneNumber ?? currentUserService.phoneNumber).trim();
  if (directEmail.isNotEmpty) parts.add(directEmail);
  if (directPhone.isNotEmpty) parts.add(directPhone);
  final directContactDetails = parts.isEmpty ? null : parts.join(', ');
  if (directContactDetails != null) return directContactDetails;

  final uid = currentUserService.effectiveUserId;
  if (uid.isEmpty) return null;
  final raw = await userRepository.getUserRaw(uid, preferCache: true);
  if (raw == null) return null;

  final fallbackParts = <String>[];
  final email = (raw['email'] ?? '').toString().trim();
  final phone = (raw['phoneNumber'] ?? '').toString().trim();
  if (email.isNotEmpty) fallbackParts.add(email);
  if (phone.isNotEmpty) fallbackParts.add(phone);
  if (fallbackParts.isEmpty) return null;
  return fallbackParts.join(', ');
}

class _PersonalDetailsCard extends StatelessWidget {
  const _PersonalDetailsCard({
    required this.contactDetails,
    required this.onContactTap,
  });

  final String? contactDetails;
  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (contactDetails != null)
        _PersonalDetailRow(
          title: 'account_center.contact_info'.tr,
          value: contactDetails!,
          onTap: onContactTap,
        ),
    ];
    if (rows.isEmpty) {
      return _buildAccountCenterCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: _buildAccountCenterEmptyText(
          'account_center.no_personal_detail'.tr,
        ),
      );
    }

    return _buildAccountCenterCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              const Divider(height: 1, indent: 18, endIndent: 18),
          ],
        ],
      ),
    );
  }
}

class _PersonalDetailRow extends StatelessWidget {
  const _PersonalDetailRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _buildAccountCenterRowShell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: _buildAccountCenterInfoContent(
                title: title,
                value: value,
              ),
            ),
            _buildAccountCenterChevron(),
          ],
        ),
      ),
    );
  }
}
