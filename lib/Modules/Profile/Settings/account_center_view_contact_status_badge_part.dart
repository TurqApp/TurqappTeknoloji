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

    return _buildVerifiedStatusBadge(
      statusColor: statusColor,
      statusText: statusText,
    );
  }
}
