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
