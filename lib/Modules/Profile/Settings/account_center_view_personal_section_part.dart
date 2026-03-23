part of 'account_center_view.dart';

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
