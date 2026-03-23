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
