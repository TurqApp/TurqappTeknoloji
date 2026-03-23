part of 'account_center_view.dart';

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.avatar,
    required this.onTap,
    required this.onLongPress,
  });

  final StoredAccount account;
  final Widget avatar;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return _buildAccountCenterRowShell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: _buildAccountRowBody(),
    );
  }
}
