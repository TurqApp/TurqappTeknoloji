part of 'account_center_view.dart';

extension AccountCenterViewContactDetailsContentPart on _ContactDetailsView {
  Widget _buildContactDetailsContent(CurrentUserService currentUserService) {
    return Obx(() {
      final email = _emailValue(currentUserService);
      final phone = _phoneValue(currentUserService);
      final emailVerified = currentUserService.emailVerifiedRx.value;
      final phoneVerified = phone.isNotEmpty;
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            _ContactStatusRow(
              icon: CupertinoIcons.mail,
              title: 'account_center.email'.tr,
              value:
                  email.isNotEmpty ? email : 'account_center.email_missing'.tr,
              isVerified: emailVerified,
              verifiedLabel: 'account_center.verified'.tr,
              pendingLabel: 'account_center.verify'.tr,
              onTap: () => Get.to(() => EditorEmail()),
            ),
            const Divider(height: 1, indent: 18, endIndent: 18),
            _ContactStatusRow(
              icon: CupertinoIcons.phone,
              title: 'account_center.phone'.tr,
              value:
                  phone.isNotEmpty ? phone : 'account_center.phone_missing'.tr,
              isVerified: phoneVerified,
              verifiedLabel: 'account_center.verified'.tr,
              pendingLabel: 'account_center.unverified'.tr,
              onTap: () => Get.to(() => EditorPhoneNumber()),
            ),
          ],
        ),
      );
    });
  }
}
