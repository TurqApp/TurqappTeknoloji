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
    return _buildPersonalFuture(currentUid);
  }
}
