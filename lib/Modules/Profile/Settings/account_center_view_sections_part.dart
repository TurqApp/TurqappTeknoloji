part of 'account_center_view.dart';

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
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Text(
          'account_center.no_personal_detail'.tr,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontFamily: 'MontserratMedium',
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
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

class _PersonalDetailsSection extends StatelessWidget {
  const _PersonalDetailsSection({
    required this.currentUserService,
    required this.userRepository,
    required this.onContactTap,
  });

  final CurrentUserService currentUserService;
  final UserRepository userRepository;
  final VoidCallback onContactTap;

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  Future<String?> _loadContactDetails() async {
    final current = currentUserService.currentUser;
    final parts = <String>[];

    final directEmail = (current?.email ?? currentUserService.email).trim();
    final directPhone =
        (current?.phoneNumber ?? currentUserService.phoneNumber).trim();
    if (directEmail.isNotEmpty) parts.add(directEmail);
    if (directPhone.isNotEmpty) parts.add(directPhone);
    if (parts.isNotEmpty) return parts.join(', ');

    final uid = _currentUid;
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

  @override
  Widget build(BuildContext context) {
    final currentUid = _currentUid;
    return FutureBuilder<String?>(
      key: ValueKey(currentUid),
      future: _loadContactDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !(snapshot.hasData && (snapshot.data?.isNotEmpty ?? false))) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black12),
            ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.black38,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactDetailsView extends StatelessWidget {
  const _ContactDetailsView();

  String _emailValue(CurrentUserService currentUserService) {
    return currentUserService.email.trim();
  }

  String _phoneValue(CurrentUserService currentUserService) {
    return currentUserService.phoneNumber.trim();
  }

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
                  final email = _emailValue(currentUserService);
                  final phone = _phoneValue(currentUserService);
                  final emailVerified =
                      currentUserService.emailVerifiedRx.value;
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
                          value: email.isNotEmpty
                              ? email
                              : 'account_center.email_missing'.tr,
                          isVerified: emailVerified,
                          verifiedLabel: 'account_center.verified'.tr,
                          pendingLabel: 'account_center.verify'.tr,
                          onTap: () => Get.to(() => EditorEmail()),
                        ),
                        const Divider(height: 1, indent: 18, endIndent: 18),
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
