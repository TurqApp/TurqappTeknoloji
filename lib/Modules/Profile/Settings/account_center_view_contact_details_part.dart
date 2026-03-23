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
