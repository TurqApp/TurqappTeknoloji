part of 'account_center_view.dart';

extension AccountCenterViewContactStatusPendingPart on _ContactStatusRow {
  Widget _buildPendingStatusBadge({
    required Color statusColor,
    required String statusText,
  }) {
    return Text(
      statusText,
      style: TextStyle(
        color: statusColor,
        fontSize: 14,
        fontFamily: 'MontserratMedium',
      ),
    );
  }
}
