part of 'account_center_view.dart';

extension AccountCenterViewContactStatusBadgePart on _ContactStatusRow {
  Widget _buildStatusBadge() {
    final statusColor = accountCenterStatusColor;
    final statusText = accountCenterStatusText;
    if (!isVerified) {
      return _buildContactStatusText(
        statusColor: statusColor,
        statusText: statusText,
      );
    }

    return Row(
      children: [
        Icon(
          CupertinoIcons.checkmark_seal_fill,
          color: statusColor,
          size: 18,
        ),
        const SizedBox(width: 6),
        _buildContactStatusText(
          statusColor: statusColor,
          statusText: statusText,
        ),
      ],
    );
  }
}
