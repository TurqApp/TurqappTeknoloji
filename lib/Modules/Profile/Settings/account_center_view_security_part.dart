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
          child: _buildSecuritySectionLabel(),
        ),
        _buildAccountCenterCard(
          child: _buildSecurityStream(uid),
        ),
      ],
    );
  }
}
