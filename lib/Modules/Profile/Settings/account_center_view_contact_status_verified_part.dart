part of 'account_center_view.dart';

extension AccountCenterViewContactStatusVerifiedPart on _ContactStatusRow {
  Widget _buildVerifiedStatusBadge({
    required Color statusColor,
    required String statusText,
  }) {
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
