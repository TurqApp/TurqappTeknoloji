part of 'account_center_view.dart';

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
                  final emailVerified =
                      currentUserService.emailVerifiedRx.value;
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
