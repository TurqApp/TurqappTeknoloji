part of 'account_center_view.dart';

extension AccountCenterViewContactStatusPendingPart on _ContactStatusRow {
  Widget _buildPendingStatusBadge({
    required Color statusColor,
    required String statusText,
  }) {
    return _buildContactStatusText(
      statusColor: statusColor,
      statusText: statusText,
    );
  }
}
