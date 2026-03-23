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

    return _buildVerifiedStatusBadge(
      statusColor: statusColor,
      statusText: statusText,
    );
  }
}
