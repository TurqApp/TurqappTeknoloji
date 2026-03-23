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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.black54, size: 20),
              const SizedBox(width: 12),
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
              _buildStatusBadge(),
            ],
          ),
        ),
      ),
    );
  }
}
