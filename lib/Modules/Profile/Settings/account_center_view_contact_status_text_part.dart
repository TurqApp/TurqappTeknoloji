part of 'account_center_view.dart';

extension AccountCenterViewContactStatusTextPart on _ContactStatusRow {
  Widget _buildContactStatusText({
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
