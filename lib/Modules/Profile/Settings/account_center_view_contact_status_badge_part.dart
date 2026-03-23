part of 'account_center_view.dart';

extension AccountCenterViewContactStatusBadgePart on _ContactStatusRow {
  Widget _buildStatusBadge() {
    final statusColor = isVerified ? Colors.green : Colors.blueAccent;
    final statusText = isVerified ? verifiedLabel : pendingLabel;
    if (!isVerified) {
      return Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 14,
          fontFamily: 'MontserratMedium',
        ),
      );
    }

    return Row(
      children: [
        const Icon(
          CupertinoIcons.checkmark_seal_fill,
          color: Colors.green,
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
    );
  }
}
