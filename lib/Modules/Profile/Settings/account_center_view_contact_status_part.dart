part of 'account_center_view.dart';

class _ContactStatusRow extends StatelessWidget {
  const _ContactStatusRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.isVerified,
    required this.verifiedLabel,
    required this.pendingLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isVerified;
  final String verifiedLabel;
  final String pendingLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = accountCenterStatusColor;
    final statusText = accountCenterStatusText;

    return _buildAccountCenterRowShell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54, size: 20),
            const SizedBox(width: 12),
            Expanded(child: _buildContactStatusContent()),
            if (!isVerified)
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 14,
                  fontFamily: 'MontserratMedium',
                ),
              )
            else
              Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
