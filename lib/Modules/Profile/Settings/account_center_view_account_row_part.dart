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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 14),
              Expanded(child: _buildAccountIdentity()),
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
